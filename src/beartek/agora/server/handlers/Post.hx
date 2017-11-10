//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.handlers;

import beartek.agora.types.Tpost;
import beartek.agora.types.Tid;
import beartek.agora.types.Types;
import beartek.agora.Utils;
import htmlparser.HtmlDocument;

@:keep class Post {
  var posts : models.PostsManager = Main.db.posts;
  var posts_info : models.PostsInfoManager = Main.db.postsInfo;

  public function new() {
    Main.connection.register_create_handler('post', this.on_post);
    Main.connection.register_create_handler('edit_post', this.on_edit_post);
    Main.connection.register_get_handler('post', Main.connection.create_sender(Main.connection.send_post, this.on_get_post));
    Main.connection.register_get_handler('full_post', Main.connection.create_sender(Main.connection.send_post, this.on_get_full_post));
    Main.connection.register_remove_handler('post', this.on_remove);
  }

  public function get_post( id : Tid, full : Bool = true ) : beartek.agora.types.Post {
    if( id.get().type.getName() != Items_types.Post_item.getName() ) throw {type: 6, msg: 'Invalid post id'};
    var post : beartek.agora.types.Post = this.obtain_post(id);
    if(post == null) throw {type: 10, msg: 'Post doesnt exists'};

    if( full ) {
      return post;
    } else {
      post.info = null;
      return post;
    }
  }

  public function get_post_info( id : Tid, popularity : Bool = false ) : beartek.agora.types.Post_info {
    var info = posts_info.get(id.toString());
    if(info.id == '') throw {type: 10, msg: 'Post doesnt exist'};

    if( popularity ) {
      this.add_popularity(info, 1);
    }

    return to_post_info(info);
  }

  public inline function to_post_info( info : models.PostsInfo ) : beartek.agora.types.Post_info {
    return {id: Tid.fromString(info.id).get(),
            title: info.title, subtitle: info.subtitle,
            overview: info.overview, publish_date: info.publish_date,
            author: Main.handlers.user.get_user(Tid.fromString(info.author_id)).get()};
  }

  private inline function obtain_post( id : Tid ) : beartek.agora.types.Post {
    return {info: this.get_post_info(id, true), content: new HtmlDocument(posts.get(id.toString()).content), tags: []};
  }

  public function add_popularity( post : models.PostsInfo, pts : Int ) : Void {
    if( new datetime.DateTime(post.last_access).getDay() < datetime.DateTime.now().getDay() ) {
      post.day_popularity = pts;
    } else {
      post.day_popularity += pts;
    }
    post.total_popularity += pts;
    post.last_access = datetime.DateTime.now();
    post.save();
  }

  public function get_random( n = 10 ) : Array<beartek.agora.types.Post_info> {
    var result : Array<beartek.agora.types.Post_info> = [];
    var posts : Array<models.PostsInfo> = posts_info.where('id', 'LIKE', '%' + Utils.generate_chars() + '%').orderAsc('id').findMany(n);
    if( posts.length < 1 ) {
      return get_random(n);
    }

    var i : Int = 0;
    while( i <= n && i < posts.length ) {
      try {
        result.push(to_post_info(posts[i]));
      } catch(e:Dynamic) {
        trace('Error getting post info ' + i + ': ' + e, 'error');
      }
      i++;
    }

    return result;
  }

  public function create_post( post : Tpost, author : Tid ) : Tid {
    if(author.get().type.getName() != Items_types.User_item.getName()) throw {type: 6, msg: 'Invalid author id'};
    if (post.is_draft() == false) {
       this.edit_post(post, author);
       return new Tid(post.get().info.id);
    } else {
      var post_id : Tid = generate_id(author.get());

      save_post(post, author, post_id);
      trace( 'Post created', 'sucess' );
      return post_id;
    }
  }

  private function generate_id( author : Id ) : Tid {
    var id = Tid.generate_id(author.host, Post_item, author.first);
    if( posts_info.get(id.toString()) == null ) {
      return id;
    } else {
      return generate_id(author);
    }
  }

  public function edit_post( post : Tpost, author : Tid ) : Void {
    if (post.is_draft()) {
      this.create_post(post, author);
    } else {
      if(post.is_full()) throw {type: 12, msg: 'The post is a full post'};
      if(author.get().type.getName() != Items_types.User_item.getName()) throw {type: 6, msg: 'Invalid author id'};
      if(Tid.equal(author.get(), post.get().info.author.id)) throw {type: 7, msg: 'Authors are differents'};

      save_edit_post(post, author, new Tid(post.get().info.id));
    }
  }

  //TODO: remover bool
  public function remove_post( id : Tid ) : Bool {
    posts.delete(id.toString());
    posts_info.delete(id.toString());
    return true;
  }

  private function save_post( post : Tpost, author_id : Tid, id : Tid ) : Void {
    posts.create(id.toString(), post.get().content.toString());
    posts_info.create(id.toString(), post.get().info.title, post.get().info.subtitle, post.get().info.overview, author_id.toString(), datetime.DateTime.now(), null, 0, 0, datetime.DateTime.now());
  }

  private function save_edit_post( post : Tpost, author_id : Tid, id : Tid ) : Void {
    var db_post = posts.get(id.toString());
    var db_info = posts_info.get(id.toString());

    db_post.set(post.get().content.toString());
    db_post.save();

    db_info.title = post.get().info.title;
    db_info.subtitle = post.get().info.subtitle;
    db_info.overview = post.get().info.overview;
    db_info.author_id = author_id.toString();
    db_info.publish_date = post.get().info.publish_date;
    db_info.edit_date = datetime.DateTime.now();
    db_info.save();
  }

  private function on_get_post( post_id : Id ) : Tpost {
   return new Tpost(this.get_post(new Tid(post_id), false));
  }

  private function on_get_full_post( post_id : Id ) : Tpost {
    return new Tpost(this.get_post(new Tid(post_id)));
  }

  private function on_post( id : Int, conn_id : String, post : beartek.agora.types.Post ) : Void {
    var post : Tpost = new Tpost(post);
    var author : Tid = Main.handlers.sessions.sessions[id];

    Main.connection.send_post_id(this.create_post(post, author), id, conn_id);
  }

  private function on_edit_post( id : Int, conn_id : String, post : beartek.agora.types.Post ) : Void {
    var post : Tpost = new Tpost(post);
    var author : Tid = Main.handlers.sessions.sessions[id];

    this.edit_post(post, author);
    Main.connection.send_post_id(new Tid(post.get().info.id), id, conn_id);
  }

  private function on_remove( id : Int, conn_id : String, post_id : Id ) : Void {
    if( Tid.equal(Main.handlers.sessions.sessions[id].get(), this.get_post_info(new Tid(post_id)).author.id) ) {
      this.remove_post(new Tid(post_id));
      Main.connection.send_post_removed(true, id, conn_id);
    } else {
      Main.connection.send_post_removed(false, id, conn_id);
    }
  }

}
