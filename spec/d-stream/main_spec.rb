# frozen_string_literal: true

describe DStream do
  describe '.map' do
    subject(:result) { transformer.call([1, 2, 3]) }

    let(:transformer) { described_class.map { |e| e * 2 } }

    it { is_expected.to be_a(Enumerator) }

    example do
      expect(result.to_a).to eq([2, 4, 6])
    end
  end

  describe '.with_next' do
    subject(:result) { transformer.call([1, 2, 3]) }

    let(:transformer) { described_class.with_next }

    it { is_expected.to be_a(Enumerator) }

    example do
      expect(result.to_a).to eq([[1, 2], [2, 3], [3, nil]])
    end
  end

  describe '.chunk' do
    subject(:result) { transformer.call([1, 1, 2, 3, 3, 3]) }

    let(:transformer) { described_class.chunk(&:even?) }

    it { is_expected.to be_a(Enumerator) }

    example do
      expect(result.to_a).to eq(
        [
          [false, [1, 1]],
          [true, [2]],
          [false, [3, 3, 3]]
        ]
      )
    end
  end
end
