class Grid::CrudPaging < Netzke::Grid::Base
  def configure(c)
    super
    c.model = 'Book'
    c.attributes = [:author__name, :title] # do not modify
    c.paging = true
    c.persistence = true
    c.store_config = {:sorters => {property: :id}}
  end
end
