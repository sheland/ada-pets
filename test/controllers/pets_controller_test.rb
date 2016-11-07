require 'test_helper'

class PetsControllerTest < ActionController::TestCase

  # Necessary setup to allow ensure we support the API JSON type
  setup do
    @request.headers['Accept'] = Mime::JSON
    @request.headers['Content-Type'] = Mime::JSON.to_s
  end

  PET_KEYS = %w( age human id name )

  def compare_pets(fixture, response)
    # Check that we didn't get any extra data
    assert_equal PET_KEYS, response.keys.sort

    # Check that the data we did get matches the fixture
    PET_KEYS.each do |key|
      assert_equal fixture[key], response[key]
    end
  end

  #
  # INDEX
  #
  test "can get #index" do
    get :index
    assert_response :success
  end

  test "#index returns json" do
    get :index
    assert_match 'application/json', response.header['Content-Type']
  end

  test "#index returns an Array of Pet objects" do
    get :index
    # Assign the result of the response from the controller action
    body = JSON.parse(response.body)
    assert_instance_of Array, body
  end

  test "returns three pet objects" do
    get :index
    body = JSON.parse(response.body)
    assert_equal 3, body.length
  end

  test "each pet object contains the relevant keys" do
    get :index
    body = JSON.parse(response.body)
    assert_equal PET_KEYS, body.map(&:keys).flatten.uniq.sort
  end

  #
  # SHOW
  #
  test "can #show a pet that exists" do
    # Send the request
    get :show, { id: pets(:one).id }
    assert_response :success

    # Check the response
    assert_match 'application/json', response.header['Content-Type']
    body = JSON.parse(response.body)
    assert_instance_of Hash, body

    compare_pets(pets(:one), body)
  end

  test "#show for a id that doesn't exist returns no content" do
    # Send the request
    get :show, { id: 12345 }
    assert_response :not_found

    assert_empty response.body
  end

  #
  # SEARCH
  #
  def send_search_request(query)
    get :search, { query: query }
    assert_response :success

    # Check the response
    assert_match 'application/json', response.header['Content-Type']
    body = JSON.parse(response.body)
    assert_instance_of Array, body

    return body
  end

  test "#search for one match should return that match" do
    body = send_search_request(pets(:three).name)

    assert_equal 1, body.length
    compare_pets(pets(:three), body.first)
  end

  test "#search with no matches returns an empty array" do
    body = send_search_request('xxzxxcxvx')

    assert_equal 0, body.length
  end

  test "#search with multiple matches returns multiple entries" do
    body = send_search_request('o')

    assert_equal 2, body.length

    body.each do |pet|
      assert_instance_of Hash, pet
      assert_equal PET_KEYS, pet.keys.sort
    end
  end

  test "#search is case insensitive" do
    body = send_search_request(pets(:three).name.upcase)

    assert_equal 1, body.length
    compare_pets(pets(:three), body.first)
  end

  test "#search returns partial matches" do
    body = send_search_request("sprout")

    assert_equal 1, body.length
    compare_pets(pets(:three), body.first)
  end
end

# # These are equivalent
# keys = %w( age human id name )
# keys.map(&:upcase)
# # and
# keys.map do |key|
#   key.upcase
# end
