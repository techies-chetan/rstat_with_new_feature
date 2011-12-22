class StockFeed
  include MongoMapper::Document
  key :update_id, String
  key :stock_symbol, String
  key :author_id, String
  key :text, String

end
