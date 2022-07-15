require 'sqlite3'

class Post

  # Статическое поле класса или class variable
  # аналогично статическим методам принадлежит всему классу в целом
  # и доступно незвисимо от созданных объектов
  @@SQLITE_DB_FILE = 'notepad.db'

  def self.post_types  # def self.имя_метода - объявление статического метода
    # Теперь нам нужно будет читать объекты из базы данных
    # поэтому удобнее всегда иметь под рукой связь между классом и его именем в виде строки
    {"Memo" => Memo, "Task" => Task, "Link" => Link}
  end

  # Параметром теперь является строковое имя нужного класса
  def self.create(type)
    return  post_types[type].new
  end

  def self.find_by_id(id)

    # Если id не передали, мы ничего не ищем, а возвращаем nil
    return if id.nil?

    db = SQLite3::Database.open(@@SQLITE_DB_FILE) # открываем "соединение" к базе SQLite

      db.results_as_hash = true # настройка соединения к базе, он результаты из базы преобразует в Руби хэши
      # выполняем наш запрос, он возвращает массив результатов, в нашем случае из одного элемента
      result = db.execute("SELECT * FROM posts WHERE  rowid = ?", id)

      db.close

      # Если в результате запроса получили пустой массис, снова возвращаем nil
      return nil if result.empty?

      # Если результат не пуст, едем дальше
      result = result[0]
      # создаем с помощью нашего же метода create экземпляр поста,
      # тип поста мы взяли из массива результатов [:type]
      # номер этого типа в нашем массиве post_type нашли с помощью метода Array#find_index
      post = create(result['type'])

      #   заполним этот пост содержимым
      post.load_data(result)

      # и вернем его
      return post

  end

  # Метод класса find_all возвращает массив записей из базы данных, который
  # можно например показать в виде таблицы на экране.
  def self.find_all(limit, type)
    db = SQLite3::Database.open(@@SQLITE_DB_FILE)
    db.results_as_hash = false # настройка соединения к базе, он результаты из базы НЕ преобразует в Руби хэши

    # формируем запрос в базу с нужными условиями
    query = "SELECT rowid, * FROM posts "

    query += "WHERE type = :type " unless type.nil? # если задан тип, надо добавить условие
    query += "ORDER by rowid DESC " # и наконец сортировка - самые свежие в начале. ASC сортировка по возрастанию

    query += "LIMIT :limit " unless limit.nil? # если задан лимит, надо добавить условие

    # готовим запрос в базу, как плов :)
    begin
    statement = db.prepare query
    rescue SQLite3::SQLException => e
      puts "Не удалось выполнить запрос в базе #{@@SQLITE_DB_FILE}"
      abort e.message
    end

    statement.bind_param('type', type) unless type.nil? # загружаем в запрос тип вместо плейсхолдера, добавляем лук :)
    statement.bind_param('limit', limit) unless limit.nil? # загружаем лимит вместо плейсхолдера, добавляем морковь :)

    result = statement.execute! #(query) # выполняем
    statement.close
    db.close

    result
  end

  # def self.find(limit, type, id)
  #
  #   db = SQLite3::Database.open(@@SQLITE_DB_FILE) # открываем "соединение" к базе SQLite
  #   if !id.nil?
  #     db.results_as_hash = true # настройка соединения к базе, он результаты из базы преобразует в Руби хэши
  #     # выполняем наш запрос, он возвращает массив результатов, в нашем случае из одного элемента
  #     result = db.execute("SELECT * FROM posts WHERE  rowid = ?", id)
  #     # получаем единственный результат (если вернулся массив)
  #     result = result[0] if result.is_a? Array
  #     db.close
  #
  #     if result.empty?
  #       puts "Такой id #{id} не найден в базе :("
  #       return nil
  #     else
  #       # создаем с помощью нашего же метода create экземпляр поста,
  #       # тип поста мы взяли из массива результатов [:type]
  #       # номер этого типа в нашем массиве post_type нашли с помощью метода Array#find_index
  #       post = create(result['type'])
  #
  #       #   заполним этот пост содержимым
  #       post.load_data(result)
  #
  #       # и вернем его
  #       return post
  #     end
  #
  #     # эта ветвь выполняется если не передан идентификатор
  #   else
  #
  #     db.results_as_hash = false # настройка соединения к базе, он результаты из базы НЕ преобразует в Руби хэши
  #
  #     # формируем запрос в базу с нужными условиями
  #     query = "SELECT rowid, * FROM posts "
  #
  #     query += "WHERE type = :type " unless type.nil? # если задан тип, надо добавить условие
  #     query += "ORDER by rowid DESC " # и наконец сортировка - самые свежие в начале. ASC сортировка по возрастанию
  #
  #     query += "LIMIT :limit " unless limit.nil? # если задан лимит, надо добавить условие
  #
  #     # готовим запрос в базу, как плов :)
  #     statement = db.prepare query
  #
  #     statement.bind_param('type', type) unless type.nil? # загружаем в запрос тип вместо плейсхолдера, добавляем лук :)
  #     statement.bind_param('limit', limit) unless limit.nil? # загружаем лимит вместо плейсхолдера, добавляем морковь :)
  #
  #     result = statement.execute! #(query) # выполняем
  #     statement.close
  #     db.close
  #
  #
  #     return result
  #   end
  # end

  def initialize
    @created_at = Time.now
    @text = nil
  end

  def read_from_console
    # todo
  end

  def to_strings
    # todo
  end

  def save
    file = File.new(file_path, "w:UTF-8")

    for item in to_strings do
      file.puts(item)
    end

    file.close
  end

  def file_path
    current_path = File.dirname(__FILE__)

    file_name = @created_at.strftime("#{self.class.name}_%Y-%m-%d_%H-%M-%S.txt")

    return current_path + "/" + file_name
  end

  # Наконец, вот он метод, сохраняющий состояние объекта в базу данных
  def save_to_db
    db = SQLite3::Database.open(@@SQLITE_DB_FILE) # открываем "соединение" к базе SQLite

    db.results_as_hash = true # настройка соединения к базе, он результаты из базы преобразует в Руби хэши


    # запрос к базе на вставку новой записи в соответствии с хэшом, сформированным дочерним классом to_db_hash
    begin
    db.execute(
        "INSERT INTO posts (" +
            to_db_hash.keys.join(',') + # все поля, перечисленные через запятую
            ")" +
            "VALUES (" +
            ("?,"*to_db_hash.keys.size).chomp(',') + # строка из заданного числа _плейсхолдеров_ ?,?,?...
            ")",
        to_db_hash.values
    )

    rescue SQLite3::SQLException
      puts "Не удалось выполнить запрос в базе #{@@SQLITE_DB_FILE}"
      puts "no such table: posts"
    end
    insert_row_id = db.last_insert_row_id
    db.close

    # возвращаем идентификатор записи в базе
    return  insert_row_id
  end

  # Метод to_db_hash возвращает хэш вида {'имя_столбца' => 'значение'}
  # для сохранения в базу данных новой записи
  def to_db_hash
    # дочерние классы сами знают свое представление, но общие для всех классов поля
    # можно заполнить уже сейчас в базовом классе!
    {
        # self — ключевое слово, указывает на 'этот объект',
        # то есть конкретный экземпляр класса, где выполняется в данный момент этот код
        'type' => self.class.name,
        'created_at' => @created_at.to_s
    }
    # todo: дочерние классы должны дополнять этот хэш массив своими полями
  end

  # Получает на вход хэш массив данных и должен заполнить свои поля
  def load_data(data_hash)
    @created_at = Time.parse(data_hash['created_at'])
    #  todo: остальные специфичные поля должны заполнить дочерние классы
  end
end

# PS: Весь набор методов, объявленных в родительском классе называется интерфейсом класса
# Дети могут по–разному реализовывать методы, но они должны подчиняться общей идее
# и набору функций, которые заявлены в базовом (родительском классе)