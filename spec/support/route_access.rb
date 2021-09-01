RSpec.shared_examples "it has route access" do
  it 'has access to routes' do
    expect(subject).to respond_to(:url_helpers)
  end
end
