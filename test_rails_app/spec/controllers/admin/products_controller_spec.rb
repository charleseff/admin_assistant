require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::ProductsController do
  integrate_views
  
  describe '#index with at least one Product' do
    before :all do
      @product = (
        Product.find(:first) || Product.create!(:name => 'product name')
      )
    end
    
    before :each do
      get :index
    end
    
    it 'should have a search form that allows you to specify equals or other options' do
      response.should have_tag('form[id=search_form][method=get]') do
        with_tag("select[name=?]", "search[price(comparator)]") do
          with_tag("option[value='>']", :text => 'greater than')
          with_tag("option[value='>=']", :text => 'greater than or equal to')
          with_tag("option[value='='][selected=selected]", :text => 'equal to')
          with_tag("option[value='<=']", :text => 'less than or equal to')
          with_tag("option[value='<']", :text => 'less than')
        end
        with_tag('input[name=?]', 'search[price]')
      end
    end
    
    it 'should not have a comparator for the name search field' do
      response.should have_tag('form[id=search_form][method=get]') do
        without_tag("select[name=?]", "search[name(comparator)]")
      end
    end
    
    it 'should not have a Show link' do
      response.should_not have_tag(
        "a[href=/admin/products/show/#{@product.id}]", 'Show'
      )
    end
  end
  
  describe '#index search by price' do
    before :all do
      Product.destroy_all
      Product.create!(:name => 'Chocolate bar', :price => 200)
      Product.create!(:name => 'Diamond ring', :price => 200_000)
    end
    
    before :each do
      get :index, :search => {"price(comparator)" => '>', :price => 1000}
    end
    
    it 'should only show products more expensive than $10' do
      response.should_not have_tag('td', :text => 'Chocolate bar')
      response.should have_tag('td', :text => 'Diamond ring')
    end
    
    it 'should show the price comparison in the search form' do
      response.should have_tag('form[id=search_form][method=get]') do
        with_tag("select[name=?]", "search[price(comparator)]") do
          with_tag(
            "option[value='>'][selected=selected]", :text => 'greater than'
          )
          with_tag("option[value='>=']", :text => 'greater than or equal to')
          with_tag("option[value='=']", :text => 'equal to')
          with_tag("option[value='<=']", :text => 'less than or equal to')
          with_tag("option[value='<']", :text => 'less than')
        end
        with_tag('input[name=?]', 'search[price]')
      end
    end
  end
  
  describe '#new' do
    before :each do
      get :new
      response.should be_success
    end
    
    it 'should not render the default price input' do
      response.should_not have_tag("input[name=?]", 'product[price]')
    end
    
    it 'should render the custom price input from _price_input.html.erb' do
      response.should have_tag("input[name=?]", 'product[price][dollars]')
    end
  end
  
  describe '#edit' do
    before :all do
      @product = Product.find_or_create_by_name 'a bird'
      @product.update_attributes(
        :name => 'a bird', :price => 100_00,
        :file_column_image => File.open("./spec/data/ruby_throated.jpg")
      )
    end
    
    before :each do
      get :edit, :id => @product.id
      response.should be_success
    end
    
    it "should have a multipart form" do
      response.should have_tag('form[enctype=multipart/form-data]')
    end
    
    it 'should have a file input for image' do
      response.should have_tag(
        'input[name=?][type=file]', 'product[file_column_image]'
      )
    end
    
    it 'should show the current image' do
      response.should have_tag(
        "img[src^=?]",
        "/product/file_column_image/#{@product.id}/ruby_throated.jpg"
      )
    end
    
    it 'should have a remove-image option' do
      response.should have_tag(
        "input[type=checkbox][name=?]", 'product[file_column_image(destroy)]'
      )
    end
  end
  
  describe '#update' do
    before :all do
      @product = Product.find_or_create_by_name 'a bird'
      @product.update_attributes(
        :name => 'a bird', :price => 100_00,
        :file_column_image => File.open("./spec/data/ruby_throated.jpg")
      )
    end
    
    describe 'while updating a current image' do
      before :each do
        file = File.new './spec/data/tweenbot.jpg'
        post(
          :update, :id => @product.id, :product => {:file_column_image => file}
        )
      end
      
      it 'should update the image' do
        product_prime = Product.find_by_id @product.id
        product_prime.file_column_image.should match(/tweenbot/)
      end
    
      it 'should save the image locally' do
        assert(
          File.exist?(
            "./public/product/file_column_image/#{@product.id}/tweenbot.jpg"
          )
        )
      end
    end
    
    describe 'while removing the current image' do
      before :each do
        post(
          :update,
          :id => @product.id,
          :product => {
            'file_column_image(destroy)' => '1', :file_column_image => ''
          }
        )
      end
      
      it 'should remove the existing image' do
        product_prime = Product.find_by_id @product.id
        product_prime.file_column_image.should be_nil
      end
    end
    
    describe 'while trying to update and remove at the same time' do
      before :each do
        file = File.new './spec/data/tweenbot.jpg'
        post(
          :update,
          :id => @product.id,
          :product => {
            :file_column_image => file, 'file_column_image(destroy)' => '1'
          }
        )
      end

      it 'should assume you meant to update' do
        product_prime = Product.find_by_id @product.id
        product_prime.file_column_image.should match(/tweenbot/)
      end
    end
  end
end
