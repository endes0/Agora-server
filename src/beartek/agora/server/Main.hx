//Under GNU AGPL v3, see LICENCE

package beartek.agora.server;

import beartek.utils.Wtps;
import beartek.utils.Wtp_types;
import beartek.agora.server.handlers.*;
import beartek.agora.types.Tid;
import orm.Db;


typedef Handlers = {
  var token : Token;
  var sessions : Sessions;
  var user : User;
  var post : Post;
  var search : Search;
  var commands : Commands;
}

class Main {
  static public var host(get,null) : String;
  public static function get_host() : String {
    return config['connection']['host'];
  }
  static public var connection(default,null) : Protocol;
  static public var db(default,null) : models.Orm;
  static public var handlers(default,null) : Handlers;
  static public var on(default,null) : Bool = true;
  static public var db_conn : orm.Db;
  static public var config : Map<String,Map<String,String>>;

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
    var secure : {CA: String, Certificate: String, Key: String} = null;
    if( config['secure']['CA'] != null && config['secure']['key'] != null && config['secure']['certificate'] != null ) {
      secure = {CA: config['secure']['CA'], Certificate: config['secure']['certificate'], Key: config['secure']['key']};
      trace( 'Opening secure connection', 'info' );
    } else {
      trace( 'Opening insecure connection', 'warn' );
    }

    connection = new Protocol(config['connection']['host'], Std.parseInt(config['connection']['port']), Std.parseInt(config['connection']['max_clients']), secure, true);
    db_conn = new Db(config['db']['URI']);
    db = new models.Orm(db_conn);

    handlers = {token: new Token(), sessions: new Sessions(), user: new User(), post: new Post(), search: new Search(), commands: new Commands()};
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
