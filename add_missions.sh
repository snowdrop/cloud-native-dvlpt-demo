#!/usr/bin/env bash
cat <<EOF > missions.json
{
  "missions": [
    {
      "id": "jpa",
      "name": "JPA Persistence"
    }
  ]
}
EOF

declare -A missions=( ["jpa"]='JPA Persistence' ["crud"]='CRUD' ["health-check"]='Health Check')

for id in "${!missions[@]}"; do
    checkExpression='.missions | .[] | select(.id=="'${id}'")'
    checkExpressionResult=$(jq "${checkExpression}" missions.json)
    if [ -n "${checkExpressionResult}" ]; then
      continue
    fi

    name=${missions[$id]}
    addExpression='.missions += [{"id": "'${id}'", "name": "'${name}'"}]'
    jq  "${addExpression}" missions.json > temp.json && mv temp.json missions.json
done