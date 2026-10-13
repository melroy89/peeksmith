/* SPDX-License-Identifier: GPL-3.0-or-later */
using Peek.Sharing;

private const string VALID_RESPONSE = "{\"success\":true,\"data\":{\"link\":\"https://i.imgur.com/example.gif\",\"deletehash\":\"delete123\"}}";

private class UploadTests : Object {
  private Soup.Server server;
  private ImgurClient client;
  private File file;
  private string directory;
  private string response = VALID_RESPONSE;
  private uint status = 200;
  private int requests = 0;
  private bool hold = false;
  private Soup.ServerMessage? held;

  public UploadTests () throws Error {
    directory = DirUtils.make_tmp ("peeksmith-imgur-XXXXXX");
    file = File.new_for_path (Path.build_filename (directory, "private-filename.gif"));
    // A tiny valid GIF; binary payload must survive multipart encoding.
    FileUtils.set_data (file.get_path (), Base64.decode ("R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="));
    server = new Soup.Server (null, null);
    server.add_handler (null, (server, message, path, query) => {
      requests++;
      assert (path == "/3/image");
      assert (message.get_method () == "POST");
      assert (message.get_request_headers ().get_one ("Authorization") == "Client-ID test123");
      var multipart = new Soup.Multipart.from_message (message.get_request_headers (), message.get_request_body ().flatten ());
      assert (multipart != null && multipart.get_length () == 2);
      unowned Soup.MessageHeaders headers;
      unowned Bytes contents;
      assert (multipart.get_part (0, out headers, out contents));
      assert (headers.get_content_type (null) == "image/gif");
      assert (!headers.get_one ("Content-Disposition").contains ("private-filename"));
      uint8[] original;
      try { FileUtils.get_data (file.get_path (), out original); } catch (Error error) { assert_not_reached (); }
      assert (contents.compare (new Bytes (original)) == 0);
      message.set_status (status, null);
      if (status == 302) message.get_response_headers ().replace ("Location", "http://127.0.0.1:1/never-follow");
      message.set_response ("application/json", Soup.MemoryUse.COPY, response.data);
      if (hold) {
        held = message;
        server.pause_message (message);
      }
    });
    server.listen_local (0, Soup.ServerListenOptions.IPV4_ONLY);
    client = new ImgurClient.with_endpoint (server.get_uris ().data.to_string () + "3/image");
  }

  private async void expect_error (File target, string id, Quark domain, int code) throws Error {
    try {
      yield client.upload (target, id);
      assert_not_reached ();
    } catch (Error error) {
      assert (error.domain == domain && error.code == code);
    }
  }

  private static Gtk.Widget? find_widget (Gtk.Container container, string text) {
    foreach (var widget in container.get_children ()) {
      if (widget is Gtk.Button && ((Gtk.Button) widget).label == text) return widget;
      if (widget is Gtk.Label && ((Gtk.Label) widget).label.contains (text)) return widget;
      if (widget is Gtk.Container) {
        var found = find_widget ((Gtk.Container) widget, text);
        if (found != null) return found;
      }
    }
    return null;
  }

  private static async void tick () {
    Timeout.add (10, () => { tick.callback (); return Source.REMOVE; });
    yield;
  }

  private async void test_dialog () throws Error {
    var settings = new Settings ("org.melroy.Peeksmith");
    settings.set_string ("sharing-imgur-client-id", "test123");
    var parent = new Gtk.Window ();
    var dialog = new Peek.Ui.ShareDialog (parent, file, client);
    var upload = (Gtk.Button) find_widget (dialog, "Upload to Imgur");
    var copy = (Gtk.Button) find_widget (dialog, "Copy link");
    var receipt = (Gtk.Button) find_widget (dialog, "Copy deletion details");
    assert (upload.sensitive && !copy.visible && !receipt.visible);
    int before = requests;
    yield tick ();
    assert (requests == before); // Showing the dialog must never upload automatically.
    status = 429;
    upload.clicked ();
    assert (!upload.sensitive);
    for (int i = 0; i < 200 && !upload.sensitive; i++) yield tick ();
    assert (upload.sensitive);
    assert (find_widget (dialog, "HTTP 429") != null);
    status = 200;
    upload.clicked ();
    for (int i = 0; i < 200 && !copy.visible; i++) yield tick ();
    assert (copy.visible && receipt.visible && !upload.sensitive);
    copy.clicked ();
    assert (dialog.get_clipboard (Gdk.SELECTION_CLIPBOARD).wait_for_text () == "https://i.imgur.com/example.gif");
    receipt.clicked ();
    assert (dialog.get_clipboard (Gdk.SELECTION_CLIPBOARD).wait_for_text ().contains ("/image/delete123"));
    dialog.destroy ();
    hold = true;
    dialog = new Peek.Ui.ShareDialog (parent, file, client);
    upload = (Gtk.Button) find_widget (dialog, "Upload to Imgur");
    upload.clicked ();
    for (int i = 0; i < 200 && held == null; i++) yield tick ();
    assert (held != null);
    dialog.response (Gtk.ResponseType.CLOSE);
    for (int i = 0; i < 200 && !upload.sensitive; i++) yield tick ();
    assert (find_widget (dialog, "Upload cancelled") != null && upload.sensitive);
    server.unpause_message (held);
    held = null;
    dialog.destroy ();
    // Destroying the parent during an upload cancels without updating dead widgets.
    dialog = new Peek.Ui.ShareDialog (parent, file, client);
    ((Gtk.Button) find_widget (dialog, "Upload to Imgur")).clicked ();
    for (int i = 0; i < 200 && held == null; i++) yield tick ();
    assert (held != null);
    parent.destroy ();
    yield tick ();
    server.unpause_message (held);
    held = null;
    hold = false;
    yield tick ();
  }

  public async void run () throws Error {
    var result = yield client.upload (file, " test123 ");
    assert (result.link == "https://i.imgur.com/example.gif");
    assert (result.delete_hash == "delete123");
    assert (requests == 1);
    yield expect_error (file, "bad\r\nheader", (new UploadError.INVALID_FILE ("")).domain, UploadError.INVALID_CLIENT_ID);
    yield expect_error (File.new_for_path (directory + "/missing.gif"), "test123", IOError.quark (), IOError.NOT_FOUND);
    assert (requests == 1);
    var invalid = File.new_for_path (directory + "/invalid.gif");
    FileUtils.set_contents (invalid.get_path (), "not a GIF");
    yield expect_error (invalid, "test123", (new UploadError.INVALID_FILE ("")).domain, UploadError.INVALID_FILE);
    var large = File.new_for_path (directory + "/large.gif");
    var output = large.create (FileCreateFlags.NONE);
    output.truncate (ImgurClient.MAX_FILE_SIZE + 1);
    output.close ();
    yield expect_error (large, "test123", (new UploadError.INVALID_FILE ("")).domain, UploadError.INVALID_FILE);
    assert (requests == 1);
    foreach (uint code in new uint[] {401, 403, 429, 500, 302}) {
      status = code;
      yield expect_error (file, "test123", (new UploadError.INVALID_FILE ("")).domain, UploadError.HTTP);
    }
    status = 200;
    foreach (string body in new string[] {
      "not json", "[]", "{}", "{\"success\":true,\"data\":null}",
      "{\"success\":\"true\",\"data\":{}}", VALID_RESPONSE.replace ("true", "false"),
      VALID_RESPONSE.replace ("https://i.imgur.com/example.gif", "https://evil.example/a.gif"),
      VALID_RESPONSE.replace ("https:", "http:"),
      VALID_RESPONSE.replace ("i.imgur.com/", "i.imgur.com:444/"),
      VALID_RESPONSE.replace ("i.imgur.com/", "user@i.imgur.com/"),
      VALID_RESPONSE.replace ("example.gif", "example.gif?tracking=1"),
      VALID_RESPONSE.replace ("example.gif", "example.gif#fragment"),
      VALID_RESPONSE.replace ("example.gif", "example gif"),
      VALID_RESPONSE.replace ("delete123", "../bad"),
      VALID_RESPONSE.replace ("deletehash", "missing")
    }) {
      response = body;
      yield expect_error (file, "test123", (new UploadError.INVALID_FILE ("")).domain, UploadError.INVALID_RESPONSE);
    }
    response = string.nfill (65537, 'x');
    yield expect_error (file, "test123", (new UploadError.INVALID_FILE ("")).domain, UploadError.INVALID_RESPONSE);
    response = VALID_RESPONSE;
    hold = true;
    var cancel = new Cancellable ();
    Timeout.add (10, () => {
      if (held == null) return Source.CONTINUE;
      cancel.cancel ();
      return Source.REMOVE;
    });
    try {
      yield client.upload (file, "test123", cancel);
      assert_not_reached ();
    } catch (IOError.CANCELLED error) {
      assert (held != null);
    }
    // Release the server request and prove the client can be reused after cancel.
    server.unpause_message (held);
    held = null;
    hold = false;
    result = yield client.upload (file, "test123");
    assert (result.link == "https://i.imgur.com/example.gif");
    yield test_dialog ();
    server.disconnect ();
    file.delete ();
    invalid.delete ();
    large.delete ();
    File.new_for_path (directory).delete ();
  }
}

int main (string[] args) {
  Test.init (ref args);
  Gtk.init (ref args);
  Test.add_func ("/sharing/imgur", () => {
    var loop = new MainLoop ();
    try {
      var tests = new UploadTests ();
      tests.run.begin ((object, result) => {
        try { tests.run.end (result); } catch (Error error) { Test.fail (); stderr.printf ("%s\n", error.message); }
        loop.quit ();
      });
      loop.run ();
    } catch (Error error) { Test.fail (); }
  });
  return Test.run ();
}
