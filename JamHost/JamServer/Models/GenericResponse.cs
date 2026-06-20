using Microsoft.AspNetCore.Http.HttpResults;

namespace JamServer.Models;

public record GenericResponse
{
    public required string Message { get; init; } = "";

    public static BadRequest<GenericResponse> BadRequest(string message = "")
    {
        return TypedResults.BadRequest(new GenericResponse { Message = message });
    }
}