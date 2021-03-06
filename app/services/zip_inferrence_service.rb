class ZipInferrenceService

  USPS_BASE_URL = 'https://tools.usps.com/go/ZipLookupResultsAction!input.action'

  # Try to resolve the zip5 and zip4 for a user_profile
  #
  # @param user_profile [UserProfile] instance of UserProfile
  # @return
  def initialize(user_profile, force_update = false)

    # only update if empty zip5/zip4/forcing an update
    if user_profile.zipcode.blank? or user_profile.zip_four.blank? or force_update

      # try to resolve zip first with address using USPS server
      if user_profile.street_address.present? and user_profile.city.present? and user_profile.user.state.present?
        # grab data as 2 item array
        zip5_zip4 = self.class.usps_zip_lookup(user_profile.street_address, user_profile.city, user_profile.user.state)

        # validation for zip5 and set
        if zip5_zip4[0].valid_zip5?
          user_profile.zipcode = zip5_zip4[0]
        end

        # validation for zip4 and set
        if zip5_zip4[1].valid_zip4?
          user_profile.zip_four = zip5_zip4[1]
        end
      end

      # fall back to geocoder if USPS method fails
      if user_profile.zipcode.blank? or user_profile.zip_four.blank?
        result = self.class.geocoder_zip_lookup(user_profile.mailing_address)

        unless result.nil? or result.postal_code.blank?
          user_profile.zipcode = result.postal_code
          if result.respond_to?(:zip4) and not result.zip4.blank?
            user_profile.zip_four = result.zip4
          end
        end
      end

      # save data to UserProfile
      user_profile.save!
    end

  end


  # Looks up zip5 from partial address information
  #
  # @param street_address [String]
  # @param city [String]
  # @param state [String]
  # @return [String] associated zip5
  def self.zip5_lookup(street_address, city, state)
    zip5_zip4 = usps_zip_lookup(street_address, city, state)

    if zip5_zip4[0].valid_zip5?
      return zip5_zip4[0]
    end

    result = geocoder_zip_lookup(street_address + ',' + city + ',' + state)
    if not result.nil? or not result.postal_code.blank?
      return result.postal_code
    end

  end

  # Looks up zip4 from partial address information
  #
  # @param street_address [String]
  # @param city [String]
  # @param state [String]
  # @param zip5 [String]
  # @return [String] associated zip4
  def self.zip4_lookup(street_address, city, state, zip5 = '')
    zip5_zip4 = usps_zip_lookup(street_address, city, state)

    if zip5_zip4[1].valid_zip4?
      return zip5_zip4[1]
    end

    result = geocoder_zip_lookup(street_address + ',' + city + ',' + state + ' ' + zip5)
    if result.respond_to?(:zip4) and not result.zip4.blank?
      return result.zip4
    end
  end

  # Looks up zip5 and zip4 from partial address information
  #
  # @param street_address [String]
  # @param city [String]
  # @param state [String]
  # @param zip5 [String]
  # @return [Array] index 0 is zip5, index 1 is zip4
  def self.lookup(street_address, city, state, zip5 = '')
    zip5_zip4 = usps_zip_lookup(street_address, city, state)

    if zip5_zip4[0].valid_zip5? and zip5_zip4[1].valid_zip4?
      return zip5_zip4
    end

    result = geocoder_zip_lookup(street_address + ',' + city + ',' + state + ' ' + zip5)
    if not result.nil? or not result.postal_code.blank? and (result.respond_to?(:zip4) and not result.zip4.blank?)
      return [result.postal_code, result.zip4]
    end
  end

  # Use geocoder to look up zip5 and zip4
  #
  # @param addr_str [String] full mailing address string, i.e. street_address, street_address2, city zip5-zip4
  def self.geocoder_zip_lookup(addr_str)
    MultiGeocoder.search(addr_str).first
  end

  # Use usps to look up zip5 and zip4
  #
  # @param street_address [String]
  # @param city [String]
  # @param state [String]
  def self.usps_zip_lookup(street_address, city, state)

    begin
      # construct get parameters string
      get_params = "resultMode=0&companyName=&address1=#{street_address}&address2=&city=#{city}&state=#{state}&urbanCode=&postalCode=&zip="

      # create URI
      uri = URI.parse("#{USPS_BASE_URL}?#{URI.encode(get_params)}")

      # construct request
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      data = http.get2(uri.request_uri, 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.99 Safari/537.36')

      # get response body (html)
      html = data.body

      # regexp for zip5 and zip4
      zip5 = html.match(/\<span class=\"zip\".*>\d{5}\<\/span\>/).to_s.gsub(/<("[^"]*"|'[^']*'|[^'">])*>/,' ').strip
      zip4 = html.match(/\<span class=\"zip4\">\d{4}\<\/span\>/).to_s.gsub(/<("[^"]*"|'[^']*'|[^'">])*>/,' ').strip

      # return pair as array
      [zip5,zip4]
    rescue
      raise unless Rails.env.production?
      Raven.capture_exception(e)
    end
  end

end
