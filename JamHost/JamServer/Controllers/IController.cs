namespace JamServer.Controllers;

public interface IController
{
    public void Map(IEndpointRouteBuilder endpoints);
}