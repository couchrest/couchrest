require File.expand_path("../../../spec_helper", __FILE__)

describe CouchRest::StreamRowParser do

  describe :initialize do

    let :obj do
      CouchRest::StreamRowParser.new
    end

    it "should provide object" do
      expect(obj).to_not be_nil
    end

  end

  describe "#parse with rows" do

    let :obj do
      CouchRest::StreamRowParser.new
    end

    it "should parse a basic complete segment" do
      data = <<-EOF
      {
        "total_rows": 3, "offset": 0, "rows": [
          {"id": "doc1", "key": "doc1", "value": {"rev": "4324BB"}},
          {"id": "doc2", "key": "doc2", "value": {"rev":"2441HF"}},
          {"id": "doc3", "key": "doc3", "value": {"rev":"74EC24"}}
        ]
      }
      EOF
      rows = []
      obj.parse(data) do |row|
        rows << row
      end

      expect(rows.length).to eql(3)
      row = nil
      expect do
        row = MultiJson.load(rows[0])
      end.to_not raise_error
      expect(row['id']).to eql('doc1')

      head = nil
      expect do
        head = MultiJson.load(obj.header)
      end.to_not raise_error
      expect(head).to include('total_rows')
      expect(head['total_rows']).to eql(3)
    end

    it "should deal with basic data in segments" do
      data = []
      data << '{ "total_rows": 3, "offset": 0, "ro'
      data << 'ws": [  {"id": "doc1", "key": "doc1", "value": {"rev": '
      data << '"4324BB"}}, {"id": "doc2", "key": "doc2", "value": '
      data << '{"rev":"2441HF"}}, {"id": "doc3", "key": "doc3", "value": {"rev":"74EC24"}}'
      data << ']  }'

      rows = []
      data.each do |d|
        obj.parse(d) do |row|
          rows << row
        end
      end

      expect(rows.length).to eql(3)
      row = nil
      expect do
        row = MultiJson.load(rows[1])
      end.to_not raise_error
      expect(row['id']).to eql('doc2')

      head = nil
      expect do
        head = MultiJson.load(obj.header)
      end.to_not raise_error
      expect(head).to include('total_rows')
      expect(head['total_rows']).to eql(3)
    end


    it "should handle strings with '}'" do
      data = <<-EOF
      {
        "total_rows": 3, "offset": 0, "rows": [
          {"id": "doc1", "key": "doc1", "value": {"rev":"43}24BB"}},
          {"id": "doc2", "key": "doc2", "value": {"rev":"2{441HF"}},
          {"id": "doc3", "key": "doc3", "value": {"rev":"74EC24"}}
        ]
      }
      EOF
      rows = []
      obj.parse(data) do |row|
        rows << row
      end
      expect(rows.length).to eql(3)
      expect(rows.first).to match(/43}24BB/)
    end

    it "should handle escaped chars" do
      data = <<-EOF
      {
        "total_rows": 3, "offset": 0, "rows": [
          {"id": "doc1", "key": "doc1", "value": {"rev":"43\\"4BB"}},
          {"id": "doc2", "key": "doc2", "value": {"rev":"2441HF"}},
          {"id": "doc3", "key": "doc3", "value": {"rev":"74EC24"}}
        ]
      }
      EOF
      rows = []
      obj.parse(data) do |row|
        rows << row
      end
      expect(rows.length).to eql(3)
      row = MultiJson.load(rows.first)
      expect(row['value']['rev']).to match(/43"4BB/)
    end

  end


  describe "#parse with feed" do

    let :obj do
      CouchRest::StreamRowParser.new(:feed)
    end

    it "should parse a basic complete segment" do
      data = <<-EOF
        {"id": "doc1", "key": "doc1", "value": {"rev": "4324BB"}}
        {"id": "doc2", "key": "doc2", "value": {"rev":"2441HF"}}
        {"id": "doc3", "key": "doc3", "value": {"rev":"74EC24"}}
      EOF
      rows = []
      obj.parse(data) do |row|
        rows << row
      end

      expect(rows.length).to eql(3)
      row = nil
      expect do
        row = MultiJson.load(rows[0])
      end.to_not raise_error
      expect(row['id']).to eql('doc1')

      obj.header.should be_empty
    end


  end

end
