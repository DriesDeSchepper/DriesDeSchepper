source "https://rubygems.org"

# Keep a floor that includes Ruby 4 support and the currently reviewed fixes.
# No upper bound, because
# fastlane tracks Apple's APIs and pinning it means a build that stops
# working the next time App Store Connect changes underneath it.
gem "fastlane", ">= 2.241.1"

# Reviewed transitive floors for both fresh CI and existing local resolutions.
# Fastlane's dependency constraints continue to define compatible upper bounds.
gem "addressable", ">= 2.9.2"
gem "google-apis-androidpublisher_v3", ">= 0.111.0"
