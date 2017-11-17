//Under GNU AGPL v3, see LICENCE

package beartek.agora.server.handlers;

import beartek.agora.types.Tsentence;
import beartek.agora.types.Tid;
import beartek.agora.types.Types;

@:keep class Sentence {
  var sentences : models.SentencesManager = Main.db.sentences;

  public function new() : Void {
    Main.connection.register_create_handler('sentence', this.on_create);
    Main.connection.register_create_handler('edit_sentence', this.on_edit);
    Main.connection.register_get_handler('sentence', Main.connection.create_sender(Main.connection.send_sentence, function( id : Id ) : Tsentence {
      return this.get_sentence(new Tid(id));
    }));
    Main.connection.register_remove_handler('sentence', this.on_remove);
  }

  public function get_sentence( id : Tid ) : Tsentence {
    var sentence = sentences.get(id.toString());
    if(sentence.id == '') throw {type: 10, msg: 'Sentence doesnt exists'};

    this.add_popularity(sentence, 1);
    return this.to_sentence(sentence);
  }

  public inline function to_sentence( sentence : models.Sentences ) : Tsentence {
    return new Tsentence({id: Tid.fromString(sentence.id).get(),
                          author: Main.handlers.user.get_user(Tid.fromString(sentence.author_id)).get(),
                          sentence: sentence.sentence,
                          publish_date: datetime.DateTime.fromTime(sentence.publish_date),
                          edit_date: if(sentence.edit_date != null) datetime.DateTime.fromTime(sentence.edit_date) else null
                        });
  }

  public function add_popularity( sentence : models.Sentences, pts : Int ) : Void {
    if( new datetime.DateTime(sentence.last_access).getDay() < datetime.DateTime.now().getDay() ) {
      sentence.day_popularity = pts;
    } else {
      sentence.day_popularity += pts;
    }
    sentence.total_popularity += pts;
    sentence.last_access = datetime.DateTime.now();
    sentence.save();
  }

  public function get_random( n = 10 ) : Array<beartek.agora.types.Sentence> {
    var result : Array<beartek.agora.types.Sentence> = [];
    var sents : Array<models.Sentences> = sentences.where('id', 'LIKE', '%' + Utils.generate_chars() + '%').orderAsc('id').findMany(n);
    if( sents.length < 1 ) {
      return get_random(n);
    }

    var i : Int = 0;
    while( i <= n && i < sents.length ) {
      try {
        result.push(to_sentence(sents[i]).get());
      } catch(e:Dynamic) {
        trace('Error getting post info ' + i + ': ' + e, 'error');
      }
      i++;
    }

    return result;
  }

  public function create_sentence( sentence : Tsentence, author : Tid ) : Tid {
    if (sentence.is_draft() == false) {
      this.edit_sentence(sentence, author);
      return new Tid(sentence.get().id);
    } else {
      var id : Tid = generate_id(author.get());

      sentences.create(id.toString(), sentence.get().sentence, author.toString(), datetime.DateTime.now().getTime(), null, 0, 0, datetime.DateTime.now().getTime());
      trace( 'Sentence created', 'sucess' );
      return id;
    }
  }

  private function generate_id( author : Id ) : Tid {
    var id = Tid.generate_id(author.host, Sentence_item, author.first);
    if( sentences.get(id.toString()) == null ) {
      return id;
    } else {
      return generate_id(author);
    }
  }

  public function edit_sentence( sentence : Tsentence, author : Tid ) : Void {

  }

  public function remove_sentence( id : Tid ) : Void {
    sentences.delete(id.toString());
  }

  private function on_create( id : Int, conn_id : String, sentence : beartek.agora.types.Sentence ) : Void {
    var sentence : Tsentence = new Tsentence(sentence);
    var author : Tid = Main.handlers.sessions.sessions[id];

    Main.connection.send_sentence_id(this.create_sentence(sentence, author), id, conn_id);
  }

  private function on_edit( id : Int, conn_id : String, sentence : beartek.agora.types.Sentence ) : Void {
    var sentence : Tsentence = new Tsentence(sentence);
    var author : Tid = Main.handlers.sessions.sessions[id];

    this.edit_sentence(sentence, author);
    Main.connection.send_sentence_id(new Tid(sentence.get().id), id, conn_id);
  }

  private function on_remove( id : Int, conn_id : String, sentence_id : Id ) : Void {
    if( Tid.equal(Main.handlers.sessions.sessions[id].get(), this.get_sentence(new Tid(sentence_id)).get().author.id) ) {
      this.remove_sentence(new Tid(sentence_id));
      Main.connection.send_sentence_removed(true, id, conn_id);
    } else {
      Main.connection.send_sentence_removed(false, id, conn_id);
    }
  }
}
