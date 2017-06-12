class Adfs < AuthSource
	def get_url
		"/saml/new"
	end

  def self.get_saml_settings(url_base = nil)
    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new

    settings = idp_metadata_parser.parse_remote("https://adfs.laxino.com/federationmetadata/2007-06/federationmetadata.xml", false)

    url_base = 'https://test-sso.laxino.com'
    settings.issuer                         = url_base + "/saml/metadata"
    settings.assertion_consumer_service_url = url_base + "/saml/acs?app_name=signature_verifier"
    settings.assertion_consumer_logout_service_url = url_base + "/saml/logout"

    settings.private_key = "-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC6XBO44xMjkERh
yem6XeM1rXw9hXZ+HW+EnYB1skdC90MCjzODTZ+A1s9T4HJSzCPX2wMrikNYjSmc
uGTvBThZCmxwr7kSxcQV+3UmE0FgW7K+snpI6vFY2DTeQ4CpHFpF9BUjF9SMLNRz
XexOgdJUnjr9rSc70tk3MmRgE+MZKCmsiXp/Z1tAiTofwUk8iNAnGdZgqBHX8tMG
OhcZ8sWP/Ga2iYoGTR+DQk3lpK7V5MKbm554xb029hQ3BL5yMGcsuuhFuVa5wtQl
7CyeK5entrMqDgMjdwj1kXKa/kHGSU5APiiFObaFComj6A2lsHSey8bPhXoiokck
jcNAhRvRAgMBAAECggEAddxV/NBgAlXzaYUxdNR8Ji6aLK6Dyi8DoHOcEtO1jfyj
PLMkeR5Wij1Q0lNY+lRxNsskrhy7iv18G8niy+gZQvb8rif0fJLm+KAX7wSujCpy
WXi3LfaovO/AP/GhJVLxJNzBoXgozJ5tnqkAEoa4ZxvLYzRnY8Zt6iLMqJbrQbS4
fjTL//3VorNVdvORAnmm4H8bh2o15ZFukJqPEprl4a8fGTAMshM4lOe3GpPuYqvF
vZm3gnxdclKJOZ0zHCet5UYaB5c4DB2xQWq0fBoNB2Vab5MP97OF9dgfGkaT5itI
GZ1fgW+mEJ/OyMEzLlAENoqlo/XD6+soBh8aMfryAQKBgQDhKN1Ll3UtapZF32Pi
Tstpjq6bPJjAaylubG1Yt0coDzXeOZGwQ58nETV9/UcI3q66dh7gU1649dCFl2lA
noxsbjwyTt4NP/b6NusjI/d5IebYupiSsngM+MK5Z/ii4qQUe4+HoEGnbu8mBC+3
5MxfA1WaETI420iugQKSZ/gLmQKBgQDT4rUQSnX5QkCtVQMtYGg1Em2HSvXjSdtn
Dwu+v7MfbS2AYf6utcii3UVQXOiJnLnChHWL6xK4qczK4S+Y8fY8lCyX77vQcmYH
5EHgq8WtjzwaJUInMl7Oqz3E/mnJ5a0kZHHL1xbxr1g3144QYg0H4TzITIKK130M
mWt3f1T0+QKBgQDHxh4zB7ssBLo4XLCfBxJsIfDCQ820TGCCXSnX4SX9YSGGfsXJ
AvafDyHLG4J/WDTntA5JMy+EJHZTUbhNYV9uhZBbgqZ6Uxqrfza6Axt8GpxcB5N/
9WGXANCk+J8exsCWe9splwMpr7/4lxZPr221j5vQCxnoYIfobQb/J8hpYQKBgH/a
2xs7czi3a8Or+sDU3cy4k/MBnqJKHORxRcsSbgnWnZBMkZvnAWyVTJAToBX5xnXD
7BJEBQX9ICCEBW6rAsTHPKlp9dDwVvUIHWBvBleWiNPWC7cPQ/o9hoZqZnd36iR9
n9U6sxOflQINRiJIqEhK95x93n/dTA3gPeLbqO4xAoGBAKHLklDJkv5JJLeoQX+e
aJO6PCUG8gWEx3a6Rc2h9qZlyYGCUOeTZCTBES+t2cFjbIkfjxXIa4TXPkznbWke
ojjSVryeOuYQOuf1fyS1/bPX3XqY7EzQ9+CHWMyIbiimYaynU7UY/RpmdkDcxKPJ
TeQfvp0f9qTInoRQpNod+etD
-----END PRIVATE KEY-----"

    settings.certificate = "-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJAK6ZLCi3Z4JlMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMTcwNjA3MDg1NTMxWhcNMTkwNjA3MDg1NTMxWjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAulwTuOMTI5BEYcnpul3jNa18PYV2fh1vhJ2AdbJHQvdDAo8zg02fgNbP
U+ByUswj19sDK4pDWI0pnLhk7wU4WQpscK+5EsXEFft1JhNBYFuyvrJ6SOrxWNg0
3kOAqRxaRfQVIxfUjCzUc13sToHSVJ46/a0nO9LZNzJkYBPjGSgprIl6f2dbQIk6
H8FJPIjQJxnWYKgR1/LTBjoXGfLFj/xmtomKBk0fg0JN5aSu1eTCm5ueeMW9NvYU
NwS+cjBnLLroRblWucLUJewsniuXp7azKg4DI3cI9ZFymv5BxklOQD4ohTm2hQqJ
o+gNpbB0nsvGz4V6IqJHJI3DQIUb0QIDAQABo1AwTjAdBgNVHQ4EFgQUiqZxzfw9
YTwV1KuWUZZHw8OJ3GMwHwYDVR0jBBgwFoAUiqZxzfw9YTwV1KuWUZZHw8OJ3GMw
DAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOCAQEASM/Mx3bn7MjrrWXHOm0A
KfbHMVfRFQEVsyLPXBcQqFaUdqnlj6k5iKJ/nP6NK8L5WveXvAZWI3REkpLa4NwX
R9fv4GdE98yv9UDTt1zx5ltC+W8vXg8JU5oq1s0wpTNNGe41xCAjjFb6Fztg0xbC
Fbk5Y/VREqkAVvTHUKT5K0m1hcaduB/ZfMBiSv9CTsOf9TZwu387D29tr8OhpPjV
irSA/IBx/8f6/DKHkr89MnxD/xBIjOSHRcsJqBO/UMnY+x2/Qdrh6s7mTbLMWqQ6
D+lwJhbMeRSfDHYNe9FIiO53zFEc/hElANmW7hGVskz3eDohyIUZnzZOU+kXJRr7
FA==
-----END CERTIFICATE-----"

    # settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
    settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
    # settings.name_identifier_format = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
    # settings.name_identifier_format = "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"

    # Optional for most SAML IdPs
    settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"

    # Security section
    # settings.security[:authn_requests_signed] = true
    settings.security[:logout_requests_signed] = true
    settings.security[:digest_method] = XMLSecurity::Document::SHA256
    settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA256

    # settings.security[:digest_method] = XMLSecurity::Document::SHA1
    # settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA1

    # settings.security[:digest_method] = XMLSecurity::Document::SHA512
    # settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA512

    settings
  end

end