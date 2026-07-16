function linear_mine -d 'List my open Linear tickets, sorted by workflow status'
  linear-cli i list --mine --all --filter 'state.name!=Done' --filter 'state.name!=Canceled' -o json \
    | jq -r '
      def rank:
        {"In Progress":0, "In Review":1, "Todo":2, "Backlog":3, "Triage":4}[.] // 99;
      sort_by(.state.name | rank)[] |
      "\(.identifier)\t[\(.state.name)]\t\(.title)"
    ' \
    | column -t -s \t
end
