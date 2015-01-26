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

  %i(put post).each do |verb|
    it "it perform a #{verb} request on the connection" do
      connection = Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.public_send(verb, "/foo", '{"bar":"baz"}'){ [200, { "Accept" => "application/vnd.api+json" }, "bar"] }
        end
      end

      allow(consumer).to receive(:connection).and_return(connection)
      expect(consumer.public_send(verb, "foo", "bar" => "baz").body).to eql("bar")
    end
  end

  describe "#get" do
    it "performs a get request on the connection" do
      connection = Faraday.new do |builder|
        builder.adapter :test do |stub|
          stub.get("/foo"){ [200, { "Accept" => "application/vnd.api+json" }, "bar"] }
        end
      end

      allow(consumer).to receive(:connection).and_return(connection)
      expect(consumer.get("foo").body).to eql("bar")
    end

    it "forwards params" do
      response = double(body: "response")

      expect(consumer.connection).to receive(:get).with("http://google.com", foo: "bar").and_return(response)
      expect(consumer.get("http://google.com", foo: "bar").body).to eql("response")
    end

    it "merges params" do
      response = double(body: "response")

      expect(consumer.connection).to receive(:get).with("http://google.com?test=param", foo: "bar").and_return(response)
      expect(consumer.get("http://google.com?test=param", foo: "bar").body).to eql("response")
    end

    context "when there is a Faraday::Error" do
      it "raises it's own error" do
        allow(consumer.connection).to receive(:get).and_raise(Faraday::Error)

        expect{ consumer.get("/foo") }.to raise_error(JsonApiClient::Error)
      end
    end

    context "when there is a Faraday::Error::ConnectionError" do
      it "raises it's own error" do
        original_error = double
        allow(consumer.connection).to receive(:get).and_raise(Faraday::Error::ConnectionFailed.new(double))

        expect{ consumer.get("/foo") }.to raise_error(JsonApiClient::Error::ConnectionFailed)
      end
    end
  end
end
