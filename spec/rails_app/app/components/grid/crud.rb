class Grid::Crud < Netzke::Basepack::Grid
  def configure(c)
    super
    c.model = 'Book'
    c.columns = [:author__name, :title] # do not modify
    c.persistence = true
    c.store_config = {:sorters => {property: :id}}
  end
end
