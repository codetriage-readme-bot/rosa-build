json.pull_request do
  json.partial! 'pull', :pull => @pull
  json.body @pull.body
  json.closed_at @pull.issue.closed_at.to_i if @pull.merged? || @pull.closed?
  json.closed_by do
    json.partial! 'api/v1/shared/member', :member => @pull.issue.closer
  end if @pull.issue.closer
  json.merged_by do
    json.partial! 'api/v1/shared/member', :member => @pull.issue.closer
  end if @pull.merged?
  json.created_at @pull.issue.created_at.to_i
  json.updated_at @pull.issue.updated_at.to_i
end