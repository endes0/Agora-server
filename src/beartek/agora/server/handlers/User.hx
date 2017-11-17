//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.handlers;

import beartek.agora.types.Types;
import beartek.agora.types.Tuser_info;
import beartek.agora.types.Tid;
import datetime.DateTime;

@:keep class User {
  var users_info : models.UsersInfoManager = Main.db.usersInfo;

  public function new() {
    Main.connection.register_get_handler('user_info', this.on_get_user);
  }

  public inline function to_user_info( info : models.UsersInfo ) : User_info {
    return {id: Tid.fromString(info.id).get(),
            username: info.username,
            first_name: info.first_name,
            second_name: info.second_name,
            pinned_sentence: if(info.pinned_sentence != '') Tid.fromString(info.pinned_sentence).get() else null,
            image_src: info.image_src,
            join_date: datetime.DateTime.fromTime(info.join_date),
            last_login: datetime.DateTime.fromTime(info.last_login)};
  }

  public inline function get_user( id : Tid ) : Tuser_info {
    var info : models.UsersInfo = users_info.get(id.toString());
    if(info == null) throw {type: 10, msg: 'user info not found'};
    return new Tuser_info({id: id.get(),
                      username: info.username,
                      first_name: info.first_name,
                      second_name: info.second_name,
                      pinned_sentence: if(info.pinned_sentence != null) Tid.fromString(info.pinned_sentence).get() else null,
                      image_src: info.image_src,
                      join_date: new DateTime(info.join_date),
                      last_login: new DateTime(info.last_login)
                    });
  }

  //TODO: get random

  public function create_user( username : String, first_name : String, second_name : String, loginkey : haxe.Int64 ) : Tid {
    var id : Tid = generate_id();
    var info : Tuser_info = new Tuser_info({id: id.get(),
                                            username: username,
                                            first_name: first_name,
                                            second_name: second_name,
                                            join_date: datetime.DateTime.now().getTime(),
                                            last_login: datetime.DateTime.now().getTime()
                                           });

    if(users_info.where('username', '=', username).findOne() != null) throw {type: 30, msg: 'This username is alerdy in use'};

    Main.handlers.sessions.create_loginkey(id, loginkey);
    this.save_user_info(info);

    return id;
  }

  public function edit_info( info : Tuser_info ) : Void {
    this.save_user_info(info);
  }

  public inline function delete_user( id : Tid ) : Void {
    users_info.delete(id.toString());
  }

  public function change_name_or_pass( id : Tid, username : String, loginkey: haxe.Int64 ) : Void {
    var info = users_info.get(id.toString());
    info.username = username;
    Main.handlers.sessions.update_loginkey(id, loginkey);
  }

  private function generate_id() : Tid {
    var id = Tid.generate_id(Main.host, User_item);
    if( users_info.get(id.toString()) == null ) {
      return id;
    } else {
      return generate_id();
    }
  }

  private function save_user_info( info : Tuser_info ) : Void {
    var db_info : models.UsersInfo = users_info.get(new Tid(info.get().id).toString());
    if( db_info == null || db_info.id == null ) {
      users_info.create(new Tid(info.get().id).toString(),
                        info.get().username,
                        info.get().first_name,
                        info.get().second_name,
                        if(info.get().pinned_sentence == null) null else new Tid(info.get().pinned_sentence).toString(),
                        info.get().image_src,
                        info.get().join_date.getTime(),
                        info.get().last_login.getTime()
                      );
    } else {
      db_info.first_name = info.get().first_name;
      db_info.second_name = info.get().second_name;
      db_info.pinned_sentence = if(info.get().pinned_sentence == null) null else new Tid(info.get().pinned_sentence).toString();
      db_info.image_src = info.get().image_src;
      db_info.join_date = info.get().join_date;
      db_info.last_login = info.get().last_login;
      db_info.save();
    }
  }


  private function on_get_user( id : Int, conn_id : String, user_id : Id ) : Void {
    Main.connection.send_user_info( this.get_user(new Tid(user_id)), id, conn_id);
  }

}
