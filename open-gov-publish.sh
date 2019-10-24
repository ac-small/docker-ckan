#!/bin/sh

# Grab all package ids from ckan instance #
ckanapi action package_list -r http://localhost:5000 -a {INSERT_API_KEY} >> ids.json

ids=$(cat ids.json | jq -r '.[]')
# For each ID search for existing record
for i in $ids; do
        curl -s http://localhost:5000/api/action/package_show?id="$i" \
                -H "Authorization: {INSERT_API_KEY}" \
                | jq --arg i "$i" -c '.result' >> all_data.json
done

# select only datasets that are Open Government and have been modified in the last 24 hours
jq -c '. | select (.publication == "open_government" and .metadata_modified <= (now | todate) and .metadata_modified >= (now-86400 | todate))' all_data.json >> only_new_records.json

# select only datasets that pass the open release criteria checklist
jq -c '. | select(.elegible_for_release == "true" and .access_to_information == "true" and .authority_to_release == "true" and .formats == "true" and .privacy == "true" and .official_language == "true" and .security == "true" and .other == "true" and .restrictions == "unrestricted" and .imso_approval == "true" and (.ready_to_publish == "true" or .ready_to_republish == "true"))' only_new_records.json >> valid_to_be_released.json

# Remove all AAFC specific fields, and modify to fit Open Gov schema
jq -c '. |= .+{type:"dataset"}
        + {owner_org:"2ABCCA59-6C57-4886-99E7-85EC6C719218"}
        + {restrictions:"unrestricted"}
        + {collection:"primary"}
        + {jurisdiction:"federal"}
        | del(.aafc_sector)
        | del(.procured_data)
        | del(.aafc_subject)
        | del(.procured_data_organization_name)
        | del(.authoritative_source)
        | del(.drf_program_inventory)
        | del(.data_steward_email)
        | del(.elegible_for_release)
        | del(.ready_to_republish)
        | del(.publication)
        | del(.data_source_repository)
        | del(.aafc_note)
        | del(.drf_core_responsibilities)
        | del(.aafc_resource_metadata_schema)
        | del(.mint_a_doi)
        | del(.other)
        | del(.ineligibility_reason)
        | del(.authority_to_release)
        | del(.privacy)
        | del(.formats)
        | del(.security)
        | del(.official_language)
        | del(.access_to_information)
        | del(.access_restriction)
        | del(.organization)' valid_to_be_released.json >> final_released_records.json

# Load only new records into Open Government
#ckanapi load datasets -I final_released_records.json -r {DESTINATION_URL} -a {INSERT_API_KEY}

#clean up temp files
rm ids.json
rm all_data.json
rm only_new_records.json
rm final_released_records.json
rm valid_to_be_released.json
