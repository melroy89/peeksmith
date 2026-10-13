/* Copyright 2026 Melroy van den Berg <melroy@melroy.org>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
namespace Peek.Sharing {
  public errordomain UploadError {
    INVALID_FILE,
    INVALID_CLIENT_ID,
    HTTP,
    INVALID_RESPONSE
  }

  public class UploadResult : Object {
    public string link { get; construct; }
    // Keep this private capability out of logs. It permits anonymous deletion.
    public string delete_hash { get; construct; }

    public UploadResult (string link, string delete_hash) {
      Object (link: link, delete_hash: delete_hash);
    }
  }

  public class ImgurClient : Object {
    public const int MAX_FILE_SIZE = 10 * 1024 * 1024;
    private const int MAX_RESPONSE_SIZE = 64 * 1024;
    private Soup.Session session;
    private string endpoint;

    public ImgurClient () {
      this.with_endpoint ("https://api.imgur.com/3/image");
    }

    // Internal injection point for loopback tests; never configured from user input.
    internal ImgurClient.with_endpoint (string endpoint) {
      this.endpoint = endpoint;
      session = new Soup.Session ();
      session.timeout = 60;
      session.user_agent = "Peeksmith";
    }

    private static bool is_token (string value) {
      if (value.length == 0 || value.length > 128) return false;
      foreach (uint8 character in value.data) {
        if (!((character >= 'a' && character <= 'z')
            || (character >= 'A' && character <= 'Z')
            || (character >= '0' && character <= '9'))) return false;
      }
      return true;
    }

    private static async Bytes read_bounded (InputStream stream, int limit,
        Cancellable? cancellable) throws Error {
      var buffer = new ByteArray ();
      while (true) {
        var chunk = yield stream.read_bytes_async (int.min (8192, limit + 1 - (int) buffer.len),
          Priority.DEFAULT, cancellable);
        if (chunk.get_size () == 0) break;
        buffer.append (chunk.get_data ());
        if (buffer.len > limit) {
          throw new UploadError.INVALID_RESPONSE (_("The data exceeds the size limit."));
        }
      }
      return ByteArray.free_to_bytes ((owned) buffer);
    }

    public async UploadResult upload (File file, string client_id,
        Cancellable? cancellable = null) throws Error {
      var id = client_id.strip ();
      if (!is_token (id)) {
        throw new UploadError.INVALID_CLIENT_ID (_("Enter a valid public Imgur client ID."));
      }
      var info = yield file.query_info_async ("standard::size,standard::type",
        FileQueryInfoFlags.NONE, Priority.DEFAULT, cancellable);
      if (info.get_file_type () != FileType.REGULAR || info.get_size () > MAX_FILE_SIZE) {
        throw new UploadError.INVALID_FILE (_("Choose a GIF recording no larger than 10 MiB."));
      }
      var input = yield file.read_async (Priority.DEFAULT, cancellable);
      Bytes? contents = null;
      Error? read_error = null;
      try {
        contents = yield read_bounded (input, MAX_FILE_SIZE, cancellable);
      } catch (Error error) {
        read_error = error;
      }
      yield input.close_async (Priority.DEFAULT, null);
      if (read_error != null) throw read_error;
      unowned uint8[] bytes = contents.get_data ();
      if (bytes.length < 6 || (bytes[0] != 'G' || bytes[1] != 'I' || bytes[2] != 'F'
          || bytes[3] != '8' || (bytes[4] != '7' && bytes[4] != '9') || bytes[5] != 'a')) {
        throw new UploadError.INVALID_FILE (_("Imgur sharing currently supports GIF recordings only."));
      }
      var multipart = new Soup.Multipart ("multipart/form-data");
      // Avoid disclosing the local filename (which may contain private information).
      multipart.append_form_file ("image", "recording.gif", "image/gif", contents);
      multipart.append_form_string ("type", "file");
      var message = new Soup.Message.from_multipart (endpoint, multipart);
      message.add_flags (Soup.MessageFlags.NO_REDIRECT);
      message.request_headers.replace ("Authorization", "Client-ID " + id);
      var response = yield session.send_async (message, Priority.DEFAULT, cancellable);
      Bytes? body = null;
      Error? response_error = null;
      try {
        if (message.status_code < 200 || message.status_code >= 300) {
          throw new UploadError.HTTP (_("Imgur rejected the upload (HTTP %u). Check your client ID, quota and connection before trying again.").printf (message.status_code));
        }
        body = yield read_bounded (response, MAX_RESPONSE_SIZE, cancellable);
      } catch (Error error) {
        response_error = error;
      }
      yield response.close_async (Priority.DEFAULT, null);
      if (response_error != null) throw response_error;
      return parse_response (body);
    }

    private static string? string_member (Json.Object object, string key) {
      var node = object.get_member (key);
      return node != null && node.get_value_type () == typeof (string) ? node.get_string () : null;
    }

    private static UploadResult parse_response (Bytes body) throws Error {
      try {
        var parser = new Json.Parser ();
        parser.load_from_data ((string) body.get_data (), (ssize_t) body.get_size ());
        var root = parser.get_root ();
        if (root == null || root.get_node_type () != Json.NodeType.OBJECT) throw new UploadError.INVALID_RESPONSE ("");
        var object = root.get_object ();
        var success = object.get_member ("success");
        var data = object.get_member ("data");
        if (success == null || success.get_value_type () != typeof (bool) || !success.get_boolean ()
            || data == null || data.get_node_type () != Json.NodeType.OBJECT) throw new UploadError.INVALID_RESPONSE ("");
        var link = string_member (data.get_object (), "link");
        var hash = string_member (data.get_object (), "deletehash");
        if (link == null || hash == null || !is_token (hash)
            || link.contains ("\r") || link.contains ("\n") || link.contains (" ")) throw new UploadError.INVALID_RESPONSE ("");
        var uri = Uri.parse (link, UriFlags.NONE);
        if (uri.get_scheme () != "https" || uri.get_host () != "i.imgur.com"
            || uri.get_userinfo () != null || uri.get_port () != -1
            || uri.get_fragment () != null || uri.get_query () != null) throw new UploadError.INVALID_RESPONSE ("");
        return new UploadResult (link, hash);
      } catch (Error error) {
        // Do not include response bodies or deletion credentials in diagnostics.
        throw new UploadError.INVALID_RESPONSE (_("Imgur returned an invalid response. The upload may have reached the service; do not retry automatically."));
      }
    }
  }
}
