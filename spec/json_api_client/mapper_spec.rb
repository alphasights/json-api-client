require "spec_helper"

describe JsonApiClient::Mapper do
  let(:data) do
    {
      "resources" => [
        { "property" => "foo" },
        { "property" => "bar" },
      ],
    }
  end

  describe "#call" do
    it "generates a new resource and maps the values" do
      mapper = described_class.new("resources")
      resources = mapper.call(data)

      expect(resources.length).to eql(2)
      expect(resources.first.property).to eql("foo")
      expect(resources.last.property).to eql("bar")
    end

    context "if extra resource methods are passed" do
      it "makes those methods available" do
        methods = Proc.new{ def custom_method; "biz" end }
        mapper = described_class.new("resources", methods)

        resources = mapper.call(data)
        expect(resources.first.custom_method).to eql("biz")
      end
    end
  end

  context "with a compound object" do
    subject(:mapper){ described_class.new("posts") }

    context "with singular linked resource" do
      let(:data) do
        {
          "links" => {
            "posts.author" => {
              "href" => "http://example.com/users/{posts.author}",
              "type" => "user",
            },
            "posts.comments" => {
              "href" => "http://example.com/comments/{posts.comments}",
              "type" => "comments",
            }
          },
          "posts" => [{
            "id" => "1",
            "links" => {
              "author" => "1",
              "comments" => ["1", "2"],
            },
          }, {
              "id" => "2",
              "links" => {
                "author" => "1",
                "comments" => ["3"],
              },
            }],
            "linked" => {
              "users" => [{
                "id" => "1",
                "name" => "John",
              }],
              "comments" => [{
                "id" => "1",
                "body" => "foo",
              }, {
                "id" => "2",
                "body" => "bar",
              }, {
                "id" => "3",
                "body" => "baz",
              }],
            }
        }
      end

      it "maps the linked resources" do
        posts = mapper.call(data)
        expect(posts[0].author).to_not be_nil
        expect(posts[0].author.id).to eql("1")
        expect(posts[0].author.name).to eql("John")
        expect(posts[1].author).to eql(posts[0].author)

        expect(posts[0].comments[0].id).to eql("1")
        expect(posts[0].comments[0].body).to eql("foo")
        expect(posts[0].comments[1].id).to eql("2")
        expect(posts[0].comments[1].body).to eql("bar")
        expect(posts[1].comments[0].id).to eql("3")
        expect(posts[1].comments[0].body).to eql("baz")
      end
    end
  end
end
