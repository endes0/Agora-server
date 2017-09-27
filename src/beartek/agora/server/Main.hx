//Under GNU AGPL v3, see LICENCE

package beartek.agora.server;

import beartek.utils.Wtps;
import beartek.utils.Wtp_types;

class Main {
  static public var connection : Protocol;

  public function new() : Void {
    new Token_handler();

    while( true ) {
      try {
        Main.connection.refresh();
      } catch(e:Dynamic) {
        trace(e);
      }
      Sys.sleep(0.1);
    }
  }

  static function main() {
    connection = new Protocol('127.0.0.1', 8080, 100, true);

    new Main();
  }
}
