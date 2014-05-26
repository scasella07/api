require 'spec_helper'

describe ArticlesController do
  let(:article) { Article.create(doi: '123banana', title: 'hello world') }
  let(:article2) { Article.create(doi: '123apple', title: 'awesome article') }
  before(:all) do
    WebMock.disable!
    Timecop.freeze(Time.local(1990))
  end
  after(:all) do
    WebMock.enable!
    Timecop.return
  end
  before(:each) do
    reset_index
    Article.put_mapping
    [article, article2]
    ElasticMapper.index.refresh
  end

  describe "index" do
    it "should return the list of articles" do
      get :index
      results = JSON.parse(response.body)
      results['documents'].count.should == 2
      results['total'].should == 2
    end
  end

  describe "show" do
    it "should return the article corresponding to the id" do
      get :show, id: article.id
      JSON.parse(response.body)['id'].should == article.id
    end

    it "should return a 404 if article not found" do
      get :show, id: -1
      response.status.should == 404
    end
  end

  describe "create" do
    it "should return a 500 if title not provided" do
      post :create, { doi: 'abc123' }
      response.status.should == 500
      err = JSON.parse(response.body)
      err['messages']['title'].should == ["can't be blank"]
    end

    # we might eventually automatically create a DOI
    # if none is provided.
    it "should return a 500 if DOI is not provided" do
      post :create, { title: 'my awesome title' }
      response.status.should == 500
      err = JSON.parse(response.body)
      err['messages']['doi'].should == ["can't be blank"]
    end

    it "should allow an article to be created with DOI and title" do
      post :create, { title: 'my awesome title', doi: 'abc555' }
      article = JSON.parse(response.body)
      article['publication_date'].should == '1990-01-01'

      # we should have already indexed article in ES,
      # and be able to grab it.
      get :index
      results = JSON.parse(response.body)
      results['documents'].count.should == 3
      results['total'].should == 3
    end

    it "should allow publication_date to be set when creating an article" do
      # publication date is in format year-month-day,
      # the problem with a timestamp is that if the user
      # is in a country in a different time-zone,
      # publication_date could be off by a day.
      post :create, {
        title: 'my awesome title',
        doi: 'abc555',
        publication_date: '2006-3-5'
      }
      article = JSON.parse(response.body)
      article['publication_date'].should == '2006-03-05'
    end

    it "should allow authors to be set when creating an article" do
      post :create, {
        title: 'my new awesome title',
        doi: '111111',
        authors: [{
          first_name: 'Ben',
          middle_name: 'E.',
          last_name: 'Coe'
        }, {
          first_name: 'Christian',
          middle_name: 'J.',
          last_name: 'Battista'
        }]
      }
      article = Article.find_by_doi('111111')
      article.authors_denormalized.should include({
        first_name: 'Christian',
        middle_name: 'J.',
        last_name: 'Battista'
      })
    end
  end
end
