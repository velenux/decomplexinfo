require 'net/http'
require 'uri'

# this is almost straight from net/http documentation: we need it to get the
# real urls when we're following redirections
# FIXME: should cache results
# FIXME: manage wrong/unreachable URIs (raise exception?)
def get_real_url(url, limit=10)
  # return nil when the redirect limit is reached
  return nil if limit == 0

  # we'll work on this
  current_url = url

  # if url is a string, parse it to a URI object
  current_url = URI.parse(url) if url.instance_of? String

  # connect to the uri passed as argument
  response = Net::HTTP.get_response(current_url)
  case response
    when Net::HTTPSuccess then
      # found the final form, return it
      current_url
    when Net::HTTPRedirection then
      # parse the redirect location
      loc = URI.parse(response['location'])

      # next location
      next_url = loc

      # handle relative redirects if required
      next_url = current_url + loc if (loc.scheme.nil? or loc.scheme[0..3] != 'http')

      # recursively fetch the next location
      get_real_url(next_url, limit - 1)
    else
      nil
  end
end # get_real_url()

# we need this to get URI without parameters
# used to get rid of useless utm_source parameters
def get_url_without_params(uri)
  # FIXME: should cache results
  parsed = URI.parse( uri )
  parsed.scheme + '://' + parsed.host + parsed.path
end # get_url_without_params

# accepts URIs from a feed
def can_use_simple_url?(uri_list)
  # Creates a list of the URIs without parameters
  uris_wo_params = uri_list.map { |u| get_url_without_params(u) }

  # Checks if there are duplicates in the list. If there are, then the parameters
  # are meaningful (are used to differentiate page content), otherwise they are
  # (probably) just feedburner spam (utm_source)
  uris_wo_params.uniq.count === uris_wo_params.count
end # can_use_simple_url
