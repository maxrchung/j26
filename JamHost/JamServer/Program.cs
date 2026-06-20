using System.Text.Json;
using JamServer.Controllers;
using JamServer.Game;
using JamServer.Lobby;
using JamServer.Models;

var builder = WebApplication.CreateSlimBuilder(args);

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, JamJsonContext.Default);
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, GameJsonContext.Default);
    options.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
});

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

builder.Services.AddLogging();
builder.Services.AddSingleton<LobbyCoordinator>();

builder.Services.AddSingleton<LobbyController>();
builder.Services.AddSingleton<GameController>();

var app = builder.Build();

app.UseWebSockets();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    Console.WriteLine("OpenAPI is enabled");
    app.UseSwaggerUI(options => { options.SwaggerEndpoint("/openapi/v1.json", "JamServer API V1"); });
    app.MapSwaggerUI();
}

var apiRoute = app.MapGroup("/api/v1");
app.MapService<LobbyController>(apiRoute);
app.MapService<GameController>(apiRoute);

app.Run();

internal static class AppExtensions
{
    internal static void MapService<T>(this WebApplication app, IEndpointRouteBuilder endpoints) where T : IController
    {
        app.Services.GetRequiredService<T>().Map(endpoints);
    }
}