require "rails_helper"

describe 'Protected Controller Behavior', :type => :request do

  before(:all) { WebMock.disable! }
  after(:all) { WebMock.enable! }

  let(:client) do
    Oauth2::Client.create(name: 'testclient').tap do |c|
      r = c.refresh_tokens.create
      r.access_tokens.create
    end
  end
  let(:invalid_token) { 'xxxxxxxxx' }
  let(:valid_token) do
    client.refresh_tokens.first.
      access_tokens.first.token
  end

  it "should raise 401 if no auth header is provided" do
    get '/oauth_protected'
    response.status.should == 401
    response.body.should == 'unauthorized'
  end

  it "should raise 401 if invalid auth header is provided" do
    get '/oauth_protected', nil, { 'Authorization' => "Bearer #{invalid_token}" }
    response.status.should == 401
    response.body.should =~ /invalid_token/
  end

  it "should return a 200 if valid auth header is provided" do
    get '/oauth_protected', nil, { 'Authorization' => "Bearer #{valid_token}" }
    response.status.should == 200
    response.body.should =~ /{}/
  end
end
