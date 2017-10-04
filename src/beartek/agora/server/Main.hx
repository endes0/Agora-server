//Under GNU AGPL v3, see LICENCE

package beartek.agora.server;

import beartek.utils.Wtps;
import beartek.utils.Wtp_types;
import beartek.agora.server.handlers.*;
import beartek.agora.types.Tid;

typedef Handlers = {
  var token : Token;
  var sessions : Sessions;
}

class Main {
  static public var connection : Protocol;
  static public var db : models.Orm;
  static public var handlers : Handlers;

  public function new() : Void {
    while( true ) {
      try {
        Main.connection.refresh();
      } catch(e:Dynamic) {
        trace('An error ocurred: ' + e);
      }
      Sys.sleep(0.1);
    }
  }

  public static function start() : Void {
    connection = new Protocol('127.0.0.1', 8080, 100, true);
    db = new models.Orm(new orm.Db('sqlite://agora.db'));

    handlers = {token: new Token(), sessions: new Sessions()};
  }

  static function main() {
    Main.start();

    new Main();
  }
}
