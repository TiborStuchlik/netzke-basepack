require 'spec_helper'
feature Netzke::Grid::Base, js: true do
  describe "CRUD" do
    before do
      FactoryGirl.create(:author, first_name: 'Herman', last_name: 'Hesse')
      FactoryGirl.create(:author, first_name: 'Carlos', last_name: 'Castaneda')
    end

    it 'performs CRUD operations for default (buffered) grid' do
      run_mocha_spec 'grid/crud'
    end

    it 'performs CRUD operations for paging grid' do
      run_mocha_spec 'grid/crud_paging'
    end

    it 'performs CRUD operations inline' do
      run_mocha_spec 'grid/crud_inline'
    end

    it 'preforms multiediting on form with various columns' do
      run_mocha_spec 'grid/multiline_edit'
    end

    it 'performs CRUD operations on grid with both edit modes' do
      run_mocha_spec 'grid/crud_inline', component: Grid::BothEditModes
      run_mocha_spec 'grid/form_operations', component: Grid::BothEditModes
    end
  end

  describe 'multiedit' do
    before do
      FactoryGirl.create :book, title: 'A', digitized: true
      FactoryGirl.create :book, title: 'B', digitized: false
    end

    it "preserves boolean column if not set" do
      run_mocha_spec 'grid/multiedit', component: Grid::Books
      expect(Book.first.title).to eql "C"
      expect(Book.last.title).to eql "C"

      expect(Book.first.digitized).to eql true
      expect(Book.last.digitized).to eql false
    end
  end

  it 'creates records with default values', js: true do
    FactoryGirl.create :author, first_name: 'Vladimir', last_name: 'Nabokov'
    run_mocha_spec 'grid/default_values'
  end

  it 'creates records with default values inline', js: true do
    FactoryGirl.create :author, first_name: 'Vladimir', last_name: 'Nabokov'
    run_mocha_spec 'grid/default_values_inline'
  end

  it 'allows setting initial sorting on multiple columns', js: true do
    a = FactoryGirl.create :author, last_name: 'A'
    b = FactoryGirl.create :author, last_name: 'B'
    c = FactoryGirl.create :author, last_name: 'C'

    FactoryGirl.create :book, exemplars: 2, title: 'B', author: b
    FactoryGirl.create :book, exemplars: 2, title: 'A', author: a
    FactoryGirl.create :book, exemplars: 1, title: 'B', author: b
    FactoryGirl.create :book, exemplars: 2, title: 'B', author: c
    FactoryGirl.create :book, exemplars: 2, title: 'B', author: a

    run_mocha_spec 'grid/multisorting'
  end

  it 'shows proper error when model prevents deleting a record', js: true do
    FactoryGirl.create :book, title: 'Untouchable'
    run_mocha_spec 'grid/untouchable_record', component: 'Grid::Books'
  end

  it 'loads data properly being 2 instances in tabs', js: true do
    FactoryGirl.create :book
    FactoryGirl.create :book
    run_mocha_spec 'grid/in_tabs'
  end

  it 'takes custom columns renderers into account', js: true do
    castaneda = FactoryGirl.create :author, first_name: 'Carlos', last_name: 'Castaneda'
    FactoryGirl.create :book, title: 'Journey to Ixtlan', author: castaneda
    run_mocha_spec 'grid/custom_renderers'
  end

  it 'keeps row selection after grid reload', js: true do
    4.times do
      FactoryGirl.create :book
    end
    run_mocha_spec 'grid/selection', component: 'Grid::Crud'
  end

  it 'allows changing page on paging grid', js: true do
    FactoryGirl.create :book, title: 'One'
    FactoryGirl.create :book, title: 'Two'
    FactoryGirl.create :book, title: 'Three'
    FactoryGirl.create :book, title: 'Four'
    run_mocha_spec 'grid/paging'
    run_mocha_spec 'grid/paging_with_disabled_dirty_warning'
  end

  it 'handles models with custom primary key properly', js: true do
    FactoryGirl.create(:author, first_name: 'Herman', last_name: 'Hesse')
    run_mocha_spec 'grid/custom_primary_key'
  end

  it 'renders association values properly', js: true do
    author = FactoryGirl.create(:castaneda, prize_count: 0)
    book = FactoryGirl.create(:book, author_id: author.id)
    run_mocha_spec 'grid/associations'
  end

  it 'loads data when scrolled' do
    data = 600.times.with_index.map do |i| # twice the buffer size
      { first_name: "First name #{i}" }
    end
    Author.create(data)
    run_mocha_spec 'grid/buffered'
  end

  it 'can load data at once' do
    data = 33.times.with_index.map do |i|
      { first_name: "First name #{i}" }
    end
    Author.create(data)
    run_mocha_spec 'grid/with_summary'
  end

  it 'provides meta attribute accessible via the store' do
    FactoryGirl.create :book, exemplars: 1000
    FactoryGirl.create :book, exemplars: 2000
    run_mocha_spec 'grid/meta_column'
  end

  # This doesn't test actual fil upload, due to that selenium cannot attach_file to Ext JS file upload field, but it at
  # least protects a grid with file upload from some errors; file upload has to be tested manually for now :(
  it 'allows uploading attachments via form' do
    run_mocha_spec 'grid/file_upload'
    expect(Illustration.last.title).to eql "Painting"
  end

  it 'scopes data in grid with hash' do
    FactoryGirl.create :book, title: 'One'
    FactoryGirl.create :book, title: 'One'
    FactoryGirl.create :book, title: 'Two'
    run_mocha_spec 'grid/scoped_with_hash'
  end

  it 'shows author value in the association cell' do
    author = FactoryGirl.create(:author, first_name: 'Herman', last_name: 'Hesse')
    FactoryGirl.create :book, author: author
    run_mocha_spec 'grid/check_author_cell_on_edit', component: Grid::CrudInline
  end
end
