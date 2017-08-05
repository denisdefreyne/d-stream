describe 'DStream for Piperator' do
  describe '.map' do
    example do
      pipe = Piperator.pipe(DStream.map { |e| e * 2 })
      expect(pipe.call([1, 2, 3]).to_a).to eq([2, 4, 6])
    end
  end
end
