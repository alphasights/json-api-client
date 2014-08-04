require "spec_helper"

describe JsonApiClient::Resource do
  subject(:expected_proc){}
  subject(:resource) do
    Class.new do
      include (JsonApiClient::Resource)
      resource :foo
      resource_config_prefix :foo_api
      resource_methods do
        def custom_method; end
      end
    end
  end

  it "creates a mapper" do
    mapper = resource.mapper

    expect(mapper).to be_kind_of(JsonApiClient::Mapper)
    expect(resource.mapper).to equal(mapper)
    expect(mapper.primary_resource).to eql("foo")

  end

  it "creates a consumer" do
    consumer = resource.api_client

    expect(consumer).to be_kind_of(JsonApiClient::Consumer)
    expect(resource.api_client).to equal(consumer)
  end
end
