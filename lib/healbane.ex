defmodule Healbane do
  @moduledoc """
  Healbane keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  use Protox,
    files: [
      "./defs/Protobufs/deadlock/citadel_gcmessages_common.proto"
    ]

  def decode_meta(f) do
    Protox.decode(f, CMsgMatchMetaData)
  end

  def decode_match_details(match_details) do
    Protox.decode(match_details, CMsgMatchMetaDataContents)
  end
end
