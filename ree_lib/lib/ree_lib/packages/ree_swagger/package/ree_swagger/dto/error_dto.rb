
  class ReeSwagger::ErrorDto
    include ReeDto::EntityDSL

    properties(
      status: Integer,
      description: String,
      type: String,
      code: String,
      message: String
    )
  end