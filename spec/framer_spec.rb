require "helper"

describe Http2::Parser::Framer do

  let(:f) { Framer.new }

  context "common header" do
    let(:frame) {
      {
        length: 4,
        type: :headers,
        flags: [:end_stream, :reserved, :end_headers],
        stream: 15,
        payload: nil
      }
    }

    let(:bytes) { [0x04, 0x01, 0x7, 0x0000000F].pack("SCCL") }

    it "should generate common 8 byte header" do
      f.commonHeader(frame).should eq bytes
    end

    it "should parse common 8 byte header" do
      f.parse(StringIO.new(bytes)).should eq frame
    end

    it "should raise exception on invalid frame type" do
      expect {
        frame[:type] = :bogus
        f.commonHeader(frame)
      }.to raise_error(FramingException, /invalid.*type/i)
    end

    it "should raise exception on invalid stream ID" do
      expect {
        frame[:stream] = Framer::MAX_STREAM_ID + 1
        f.commonHeader(frame)
      }.to raise_error(FramingException, /stream/i)
    end

    it "should raise exception on invalid frame flag" do
      expect {
        frame[:flags] = [:bogus]
        f.commonHeader(frame)
      }.to raise_error(FramingException, /frame flag/)
    end

    it "should raise exception on invalid frame size" do
      expect {
        frame[:length] = 2**16
        f.commonHeader(frame)
      }.to raise_error(FramingException, /too large/)
    end
  end

  context "DATA" do
    it "should generate and parse bytes" do
      frame = {
        length: 4,
        type: :data,
        flags: [:end_stream, :reserved],
        stream: 1,
        payload: 'text'
      }

      bytes = f.generate(frame)
      bytes.should eq [0x4,0x0,0x3,0x1,*'text'.bytes].pack("SCCLC*")

      f.parse(StringIO.new(bytes)).should eq frame
    end
  end

  context "HEADERS" do
    it "should generate and parse bytes" do
      frame = {
        length: 20,
        type: :headers,
        flags: [:end_stream, :reserved, :end_headers],
        stream: 1,
        payload: 'header-block'
      }

      bytes = f.generate(frame)
      bytes.should eq [0x14,0x1,0x7,0x1,*'header-block'.bytes].pack("SCCLC*")
      f.parse(StringIO.new(bytes)).should eq frame
    end

    it "should carry an optional stream priority" do
      frame = {
        length: 20,
        type: :headers,
        flags: [:end_headers, :priority],
        stream: 1,
        priority: 15,
        payload: 'header-block'
      }

      bytes = f.generate(frame)
      bytes.should eq [0x14,0x1,0xc,0x1,0xf,*'header-block'.bytes].pack("SCCLLC*")
      f.parse(StringIO.new(bytes)).should eq frame
    end
  end

end
