//Under GNU AGPL v3, see LICENCE

package beartek.agora.server;

import beartek.utils.Wtps;
import beartek.utils.Wtp_types;
import beartek.agora.server.handlers.*;
import beartek.agora.types.Tid;
import orm.Db;
import hxIni.IniManager;
import hxIni.IniManager.Ini;


typedef Handlers = {
  var token : Token;
  var sessions : Sessions;
  var commands : Commands;
  var post : Post;
  var search : Search;
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
  static var db_conn : orm.Db;
  static var config : Ini;

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
    if( !sys.FileSystem.exists('agora.ini') ) {
      sys.io.File.saveContent('agora.ini', ' ');
    }
    config = IniManager.loadFromFile("agora.ini");

    if( config['connection'] == null ) config['connection'] = new Map();
    if( config['db'] == null ) config['db'] = new Map();
    if( config['secure'] == null ) config['secure'] = new Map();

    if( config['connection']['host'] == null ) config['connection']['host'] = '0.0.0.0';
    if( config['connection']['port'] == null ) config['connection']['port'] = '8080';
    if( config['connection']['max_clients'] == null ) config['connection']['max_clients'] = '100';
    if( config['db']['URI'] == null ) config['db']['URI'] = 'sqlite://agora.db';
    IniManager.writeToFile(config, "agora.ini");

    var secure : {CA: String, Certificate: String} = null;
    if( config['secure']['CA'] != null && config['secure']['certificate'] != null ) {
      var secure : {CA: String, Certificate: String} = {CA: config['secure']['CA'], Certificate: config['secure']['certificate']};
      trace( 'Opening secure connection', 'info' );
    } else {
      trace( 'Opening insecure connection', 'warn' );
    }

    connection = new Protocol(config['connection']['host'], Std.parseInt(config['connection']['port']), Std.parseInt(config['connection']['max_clients']), if(secure != null) secure else null, true);
    db_conn = new Db(config['db']['URI']);
    db = new models.Orm(db_conn);

    handlers = {token: new Token(), sessions: new Sessions(), commands: new Commands(), post: new Post(), search: new Search()};
  }

  public static function off() : Void {
    connection.close();
    db_conn.close();
    IniManager.writeToFile(config, "agora.ini");
    on = false;
  }

  static function main() {
    Main.start();

    new Main();
  }
}
