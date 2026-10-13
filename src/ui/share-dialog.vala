/* Copyright 2026 Melroy van den Berg <melroy@melroy.org>
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
namespace Peek.Ui {
  public class ShareDialog : Gtk.Dialog {
    private File file;
    private Sharing.ImgurClient client;
    private GLib.Settings settings;
    private Gtk.Entry client_id;
    private Gtk.Entry link;
    private Gtk.Label status;
    private Gtk.Spinner spinner;
    private Gtk.Button upload_button;
    private Gtk.Button copy_button;
    private Gtk.Button open_button;
    private Gtk.Button receipt_button;
    private Gtk.Button cancel_button;
    private Cancellable? cancellable;
    private Sharing.UploadResult? result;
    private bool closed = false;

    public ShareDialog (Gtk.Window parent, File file, Sharing.ImgurClient? client = null) {
      Object (transient_for: parent, modal: true, destroy_with_parent: true,
        title: _("Share recording — Peeksmith"), default_width: 480, resizable: false);
      this.file = file;
      this.client = client ?? new Sharing.ImgurClient ();
      settings = new GLib.Settings ("org.melroy.Peeksmith");
      var box = get_content_area ();
      box.margin = 18;
      box.spacing = 12;
      var explanation = new Gtk.Label (_("Upload this GIF to Imgur? Anyone with the link can view it. Review your recording for private information before sharing. GIF files up to 10 MiB are supported."));
      explanation.wrap = true;
      explanation.max_width_chars = 60;
      explanation.xalign = 0;
      box.add (explanation);
      var filename = new Gtk.Label (file.get_basename ());
      filename.ellipsize = Pango.EllipsizeMode.MIDDLE;
      filename.xalign = 0;
      box.add (filename);
      var label = new Gtk.Label (_("Public Imgur client ID (saved on this computer):"));
      label.xalign = 0;
      box.add (label);
      client_id = new Gtk.Entry ();
      client_id.text = settings.get_string ("sharing-imgur-client-id");
      client_id.max_length = 128;
      client_id.placeholder_text = _("Client ID, not client secret");
      client_id.changed.connect (() => upload_button.sensitive = result == null
        && cancellable == null && client_id.text.strip ().length > 0);
      box.add (client_id);
      box.add (new Gtk.LinkButton.with_label ("https://apidocs.imgur.com/",
        _("Imgur API documentation and application registration")));
      status = new Gtk.Label ("");
      status.wrap = true;
      status.max_width_chars = 60;
      status.xalign = 0;
      status.selectable = true;
      box.add (status);
      spinner = new Gtk.Spinner ();
      box.add (spinner);
      link = new Gtk.Entry ();
      link.editable = false;
      box.add (link);
      var actions = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
      actions.spacing = 6;
      copy_button = new Gtk.Button.with_label (_("Copy link"));
      copy_button.clicked.connect (() => get_clipboard (Gdk.SELECTION_CLIPBOARD).set_text (result.link, -1));
      actions.add (copy_button);
      open_button = new Gtk.Button.with_label (_("Open link"));
      open_button.clicked.connect (() => {
        try {
          Gtk.show_uri_on_window (this, result.link, Gdk.CURRENT_TIME);
        } catch (Error error) {
          status.label = _("Could not open the link: %s").printf (error.message);
        }
      });
      actions.add (open_button);
      receipt_button = new Gtk.Button.with_label (_("Copy deletion details"));
      receipt_button.clicked.connect (() => {
        get_clipboard (Gdk.SELECTION_CLIPBOARD).set_text (
          "Image: " + result.link + "\nDELETE https://api.imgur.com/3/image/" + result.delete_hash + "\n", -1);
        status.label = _("Deletion details copied. Keep them private: they allow removal of your anonymous upload through the Imgur API.");
      });
      actions.add (receipt_button);
      box.add (actions);
      cancel_button = (Gtk.Button) add_button (_("Close"), Gtk.ResponseType.CLOSE);
      upload_button = (Gtk.Button) add_button (_("Upload to Imgur"), Gtk.ResponseType.ACCEPT);
      upload_button.sensitive = client_id.text.strip ().length > 0;
      response.connect ((response_id) => {
        if (response_id == Gtk.ResponseType.ACCEPT && cancellable == null && result == null) {
          upload.begin ();
        } else if (cancellable != null) {
          cancellable.cancel ();
          cancel_button.sensitive = false;
        } else {
          destroy ();
        }
      });
      destroy.connect (() => {
        closed = true;
        if (cancellable != null) cancellable.cancel ();
      });
      show_all ();
      status.hide ();
      spinner.hide ();
      link.hide ();
      actions.hide ();
      copy_button.hide ();
      open_button.hide ();
      receipt_button.hide ();
      // Children are revealed individually after a successful upload.
      copy_button.no_show_all = true;
      open_button.no_show_all = true;
      receipt_button.no_show_all = true;
    }

    private async void upload () {
      var id = client_id.text.strip ();
      settings.set_string ("sharing-imgur-client-id", id);
      cancellable = new Cancellable ();
      client_id.sensitive = false;
      upload_button.sensitive = false;
      cancel_button.label = _("Cancel upload");
      status.show ();
      spinner.show ();
      spinner.start ();
      status.label = _("Uploading to Imgur…");
      try {
        result = yield client.upload (file, id, cancellable);
        if (closed) return;
        link.text = result.link;
        link.show ();
        copy_button.get_parent ().show ();
        copy_button.show ();
        open_button.show ();
        receipt_button.show ();
        status.label = _("Uploaded. Save the deletion details before closing this window if you may want to remove the image later. Imgur may convert the animation.");
      } catch (Error error) {
        if (closed) return;
        if (error is IOError.CANCELLED) {
          status.label = _("Upload cancelled. If data was already sent, Imgur may still have received it. Your local recording is unchanged.");
        } else if (error is Sharing.UploadError) {
          status.label = error.message;
        } else {
          status.label = _("Upload failed: %s. If data was already sent, Imgur may still have received it. Check your connection before trying again.").printf (error.message);
        }
      } finally {
        cancellable = null;
        if (!closed) {
          spinner.stop ();
          spinner.hide ();
          client_id.sensitive = result == null;
          upload_button.sensitive = result == null && client_id.text.strip ().length > 0;
          cancel_button.label = _("Close");
          cancel_button.sensitive = true;
        }
      }
    }
  }
}
