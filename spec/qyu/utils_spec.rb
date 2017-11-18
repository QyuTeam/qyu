# frozen_string_literal: true

RSpec.describe Qyu::Utils do
  describe '#seconds_after_time' do
    let(:start_time) { Time.parse('2017-02-14 00:00:00 +0100') }
    let(:duration) { 25 }
    let(:end_time) { Time.parse('2017-02-14 00:00:25 +0100') }

    it 'calls gets end time' do
      expect(Qyu::Utils.seconds_after_time(duration, start_time)).to eq(end_time)
    end
  end

  describe '#uuid' do
    it 'calls SecureRandom#uuid' do
      expect(SecureRandom).to receive(:uuid)
    end

    after do
      Qyu::Utils.uuid
    end
  end

  describe '#stringify_hash_keys' do
    let(:symbolized_hash) do
      {
        presence: true,
        type: :integer
      }
    end

    it 'creates a new hash with string keys' do
      expect(Qyu::Utils.stringify_hash_keys(symbolized_hash)).
        to eq({ 'presence' => true, 'type' => :integer })
    end
  end
end
