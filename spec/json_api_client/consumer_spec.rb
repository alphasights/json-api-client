require "spec_helper"

describe JsonApiClient::Consumer do
  subject(:consumer){ described_class.new("resource_api") }

  before(:each) do
    stub_const("ENV", {
      "RESOURCE_API_BASE_URL" => "https://example.com/api",
      "RESOURCE_API_TOKEN" => "token",
    })
  end

  describe "#connection" do
    it "builds a Faraday connection with an authorization header" do
      connection = consumer.connection

      expect(connection.headers["Authorization"]).to eql("Token token")
      expect(connection.builder.handlers).to include(FaradayMiddleware::ParseJson)
    end

    it "memoizes the connection response" do
      expect(consumer.connection).to equal(consumer.connection)
    end
  end

  describe "#get" do
    it "it call a GET request on the connection" do
      connection = Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.get("/foo"){ [200, { "Accept" => "application/vnd.api+json" }, "bar"] }
        end
      end

      allow(consumer).to receive(:connection).and_return(connection)
      expect(consumer.get("foo").body).to eql("bar")
    end
  end
end
