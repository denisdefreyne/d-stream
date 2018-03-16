# frozen_string_literal: true

describe DStream do
  describe '.map' do
    let(:transformer) { DStream.map { |e| e * 2 } }

    subject { transformer.call([1, 2, 3]) }

    it { is_expected.to be_a(Enumerator) }

    example do
      expect(subject.to_a).to eq([2, 4, 6])
    end
  end

  describe '.with_next' do
    let(:transformer) { DStream.with_next }

    subject { transformer.call([1, 2, 3]) }

    it { is_expected.to be_a(Enumerator) }

    example do
      expect(subject.to_a).to eq([[1, 2], [2, 3], [3, nil]])
    end
  end

  describe '.chunk' do
    let(:transformer) { DStream.chunk(&:even?) }

    subject { transformer.call([1, 1, 2, 3, 3, 3]) }

    it { is_expected.to be_a(Enumerator) }

    example do
      expect(subject.to_a).to eq(
        [
          [false, [1, 1]],
          [true, [2]],
          [false, [3, 3, 3]]
        ]
      )
    end
  end
end
