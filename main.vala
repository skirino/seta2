namespace Config {
  const int WINDOW_WIDTH = 1680;
  const int WINDOW_HEIGHT = 1050;
  const string FONT = "Monaco 12";
  const string COLOR_FOREGROUND = "rgb(255,255,255)";
  const string COLOR_BACKGROUND = "rgba(0, 0, 0, 0.6)";
  const uint SCROLL_LINES_ON_KEY_ACTION = 5;
}

const Gdk.ModifierType CONTROL_SHIFT = Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK;

class Terminal : Gtk.Paned {
  private Pid pid;
  public Vte.Terminal terminal { get; private set; }

  public Terminal(string? initial_dir = null) {
    Object();
    terminal = new Vte.Terminal();
    pack1(terminal, true, false);
    var scrollbar = new Gtk.Scrollbar(Gtk.Orientation.VERTICAL, terminal.get_vadjustment());
    pack2(scrollbar, false, false);
    terminal.set_audible_bell(false);
    terminal.set_font(Pango.FontDescription.from_string(Config.FONT));
    var rgba_fore = Gdk.RGBA();
    var rgba_back = Gdk.RGBA();
    rgba_fore.parse(Config.COLOR_FOREGROUND);
    rgba_back.parse(Config.COLOR_BACKGROUND);
    terminal.set_colors(rgba_fore, rgba_back, null);
    terminal.scrollback_lines = -1; // unlimited scrollback
    terminal.child_exited.connect(remove_this_page);
    terminal.key_press_event.connect(key_pressed);
    var shell = Environment.get_variable("SHELL");
    terminal.spawn_async(Vte.PtyFlags.DEFAULT, initial_dir, {shell}, null, 0, null, -1, null, spawn_callback);
  }

  private void spawn_callback(Vte.Terminal t, Pid p, Error? e) {
    pid = p;
    terminal.feed_child({0x08}); // Send a backspace character to correctly show the 1st prompt.
  }

  private void remove_this_page(int _status = 0) {
    var n = parent as Notebook;
    n.remove_page(n.page_num(this));
  }

  private bool key_pressed(Gdk.EventKey e) {
    if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.P) {
      var adj = terminal.get_vadjustment();
      var v = double.max(adj.get_lower(), adj.get_value() - Config.SCROLL_LINES_ON_KEY_ACTION);
      adj.set_value(v);
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.N) {
      var adj = terminal.get_vadjustment();
      var v = double.min(adj.get_upper() - adj.get_page_size(), adj.get_value() + Config.SCROLL_LINES_ON_KEY_ACTION);
      adj.set_value(v);
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.C) {
      terminal.copy_clipboard_format(Vte.Format.TEXT);
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.V) {
      terminal.paste_clipboard();
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.D) {
      remove_this_page();
      if(pid >= 0) {
        Posix.kill(pid, Posix.Signal.KILL);
        pid = -1;
      }
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.O) {
      change_directory_to_dir_other_side();
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.braceleft) {
      var w = parent.parent.parent as MainWindow;
      feed_current_dir(w.note_left);
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.braceright) {
      var w = parent.parent.parent as MainWindow;
      feed_current_dir(w.note_right);
      return true;
    }
    // Very ad-hoc support of macOS Japanese input method.
    if(e.keyval == Gdk.Key.space && e.hardware_keycode == 104) {
      switch_input_method("com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese");
      return true;
    } else if(e.keyval == Gdk.Key.space && e.hardware_keycode == 102) {
      switch_input_method("com.apple.keylayout.ABC");
      return true;
    }
    return false;
  }

  private void change_directory_to_dir_other_side() {
    var n1 = parent as Notebook;
    var w = n1.parent.parent as MainWindow;
    var t = w.get_another_notebook(n1).get_current_terminal();
    if(t != null) {
      var dir = t.get_current_directory();
      if(dir != null) {
        // Remove existing characters and then put the cd command.
        var backspaces = "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b";
        terminal.feed_child((backspaces + "cd " + dir + "\n").data);
      }
    }
  }

  private void feed_current_dir(Notebook n) {
    var t = n.get_current_terminal();
    if(t != null) {
      var dir = t.get_current_directory();
      if(dir != null) {
        terminal.feed_child(dir.data);
      }
    }
  }

  private void switch_input_method(string name) {
    Pid pid;
    Process.spawn_async(null, {"InputSourceSelector", "select", name}, null, SpawnFlags.SEARCH_PATH, null, out pid);
  }

  public string? get_current_directory() {
    var uri = terminal.get_current_directory_uri();
    if(uri == null) {
      return null;
    } else {
      // The uri starts with `file://`; find the first `/` after that.
      var i = uri.index_of_char('/', 7);
      return uri.slice(i, uri.length);
    }
  }
}

class Notebook : Gtk.Notebook {
  public bool is_shown { get; private set; }

  public Notebook() {
    Object();
    set_scrollable(true);
    show.connect(() => { is_shown = true; });
    hide.connect(() => { is_shown = false; });
    page_removed.connect(handle_page_removed);
    append_page(new Terminal());
  }

  private void handle_page_removed(Gtk.Widget child, uint page_num) {
    if(get_n_pages() == 0) {
      var w = parent.parent as MainWindow;
      w.terminate_if_no_page();
    } else {
      grab_focus();
    }
  }

  public Terminal? get_current_terminal() {
    var n = get_current_page();
    if(n == -1) {
      return null;
    }
    return get_nth_page(n) as Terminal;
  }

  public void add_terminal() {
    string initial_dir = null;
    var current = get_current_terminal();
    if(current != null) {
      initial_dir = current.get_current_directory();
    }
    var t = new Terminal(initial_dir);
    append_page(t);
    set_tab_reorderable(t, true);
    t.show_all();
  }

  public void next_terminal() {
    if(get_current_page() == get_n_pages() - 1) {
      set_current_page(0);
    } else {
      next_page();
    }
    grab_focus();
  }

  public void prev_terminal() {
    if(get_current_page() == 0) {
      set_current_page(get_n_pages() - 1);
    } else {
      prev_page();
    }
    grab_focus();
  }

  public override void grab_focus() {
    if(is_shown) {
      var t = get_current_terminal();
      if(t != null) {
        t.terminal.grab_focus();
      }
    }
  }
}

class MainWindow : Gtk.ApplicationWindow {
  public Notebook note_left { get; private set; }
  public Notebook note_right { get; private set; }

  public MainWindow(App app) {
    Object(application: app);
    title = "Seta2";
    set_default_size(Config.WINDOW_WIDTH, Config.WINDOW_HEIGHT);
    key_press_event.connect(key_pressed);
    var paned = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
    paned.set_position(Config.WINDOW_WIDTH / 2);
    add(paned);
    note_left = new Notebook();
    note_right = new Notebook();
    paned.pack1(note_left, true, false);
    paned.pack2(note_right, true, false);

    // prepare screen with alpha for transparency
    var screen = get_screen();
    if(screen.is_composited()) {
      var visual = screen.get_rgba_visual();
      if(visual == null) {
        visual = screen.get_system_visual();
      }
      set_visual(visual);
    }
  }

  public Notebook get_another_notebook(Notebook n) {
    if(n == note_left) {
      return note_right;
    } else {
      return note_left;
    }
  }

  private Notebook? focused_note() {
    var l = note_left.get_current_terminal();
    if(l != null && l.terminal.has_focus) {
      return note_left;
    }
    var r = note_right.get_current_terminal();
    if(r != null && r.terminal.has_focus) {
      return note_right;
    }
    return null;
  }

  private bool key_pressed(Gdk.EventKey e) {
    if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.T) {
      var n = focused_note();
      if(n != null) {
        n.add_terminal();
      }
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.Left) {
      expand_notebook(note_left, note_right);
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.Right) {
      expand_notebook(note_right, note_left);
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.greater) {
      var n = focused_note();
      if(n != null) {
        n.next_terminal();
      }
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.less) {
      var n = focused_note();
      if(n != null) {
        n.prev_terminal();
      }
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.L) {
      note_right.grab_focus();
      return true;
    } else if(e.state == CONTROL_SHIFT && e.keyval == Gdk.Key.H) {
      note_left.grab_focus();
      return true;
    }
    return false;
  }

  public void terminate_if_no_page() {
    var nl = note_left.get_n_pages();
    var nr = note_right.get_n_pages();
    if(nl == 0 && nr == 0) {
      application.quit();
    } else if(nl == 0) {
      hide_notebook(note_left, note_right);
    } else if(nr == 0) {
      hide_notebook(note_right, note_left);
    }
  }

  private void expand_notebook(Notebook note_to_expand, Notebook note_to_shrink) {
    if(note_to_expand.get_n_pages() == 0) {
      note_to_expand.add_terminal();
    }
    if(note_to_expand.is_shown && note_to_shrink.is_shown) {
      hide_notebook(note_to_shrink, note_to_expand);
    } else if(!note_to_expand.is_shown) {
      note_to_expand.show_all();
    }
  }

  private void hide_notebook(Notebook note_to_hide, Notebook note_another) {
    note_to_hide.hide();
    note_another.show_all();
    note_another.grab_focus();
  }
}

class App : Gtk.Application {
  private MainWindow window;

  public App() {
    Object(application_id: "skirino.seta2", flags: ApplicationFlags.NON_UNIQUE);
  }

  protected override void activate() {
    base.activate();
    window = new MainWindow(this);
    window.show_all();
  }
}

public static int main(string[] args) {
  return new App().run(null);
}
