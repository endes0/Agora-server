//Under GNU AGPL v3, see LICENCE

package beartek.agora.server;

import beartek.utils.Wtps;
import beartek.utils.Wtp_types;
import beartek.agora.server.handlers.*;
import beartek.agora.types.Tid;

typedef Handlers = {
  var token : Token;
  var sessions : Sessions;
  var commands : Commands;
  var post : Post;
  var search : Search;
}

class Main {
  static public var host : String;
  static public var connection : Protocol;
  static public var db : models.Orm;
  static public var handlers : Handlers;
  static public var on(default,null) : Bool = true;
  static var db_conn : orm.Db;

  public function new() : Void {
    while( Main.on ) {
      try {
        Main.connection.refresh();
      } catch(e:Dynamic) {
        trace('An error ocurred: ' + e);
      }
      Sys.sleep(0.1);
    }
  }

  public static function start() : Void {
    host = '0.0.0.0';
    connection = new Protocol(host, 8080, 100, true);
    db_conn = new orm.Db('sqlite://agora.db');
    db = new models.Orm(db_conn);

    handlers = {token: new Token(), sessions: new Sessions(), commands: new Commands(), post: new Post(), search: new Search()};
  }

  public static function off() : Void {
    connection.close();
    db_conn.close();
    on = false;
  }

  static function main() {
    Main.start();

    new Main();
  }
}
