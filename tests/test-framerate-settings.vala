using Peek;
using Peek.Recording;

void test_format_framerates () {
  var settings = new Settings (APP_ID);
  var config = new RecordingConfig ();
  assert (config.framerate == 10);
  var adjustment = new Gtk.Adjustment (10, 1, 60, 1, 10, 0);

  // Existing user choices for the shared frame rate stay with non-MP4 formats.
  settings.set_int ("recording-framerate", 18);
  OutputFormat.GIF.bind_framerate (settings, config, "framerate");
  OutputFormat.GIF.bind_framerate (settings, adjustment, "value");
  assert (config.framerate == 18);
  assert (adjustment.value == 18);

  OutputFormat.MP4.bind_framerate (settings, config, "framerate");
  OutputFormat.MP4.bind_framerate (settings, adjustment, "value");
  assert (config.framerate == 30);
  assert (adjustment.value == 30);
  adjustment.value = 45;
  assert (settings.get_int ("recording-mp4-framerate") == 45);
  assert (config.framerate == 45);
  assert (settings.get_int ("recording-framerate") == 18);

  foreach (var format in new OutputFormat[] { OutputFormat.GIF, OutputFormat.APNG, OutputFormat.WEBM }) {
    format.bind_framerate (settings, config, "framerate");
    format.bind_framerate (settings, adjustment, "value");
    assert (config.framerate == 18);
    assert (adjustment.value == 18);
  }
  OutputFormat.MP4.bind_framerate (settings, config, "framerate");
  assert (config.framerate == 45);
  settings.reset ("recording-mp4-framerate");
  assert (config.framerate == 30);
  settings.reset ("recording-framerate");
  OutputFormat.GIF.bind_framerate (settings, config, "framerate");
  assert (config.framerate == 10);
  Settings.unbind (config, "framerate");
  Settings.unbind (adjustment, "value");
}

void main (string[] args) {
  Test.init (ref args);
  Test.add_func ("/settings/format-framerates", test_format_framerates);
  Test.run ();
}
