using System;
using System.ServiceProcess;
using System.Runtime.InteropServices;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;

namespace INCLService_Sharp
{
    /// <summary>
    /// Main entry point for the INCLServer Windows Service
    /// </summary>
    public static class Program
    {
        public static void Main(string[] args)
        {
            // Check if running as service or console
            if (Environment.UserInteractive)
            {
                // Running as console application (for debugging)
                var host = CreateHostBuilder(args).Build();
                var service = host.Services.GetRequiredService<INCLService>();
                service.RunAsConsole();
            }
            else
            {
                // Running as Windows Service
                ServiceBase[] ServicesToRun;
                ServicesToRun = new ServiceBase[]
                {
                    new INCLService()
                };
                ServiceBase.Run(ServicesToRun);
            }
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureServices((hostContext, services) =>
                {
                    services.AddSingleton<INCLService>();
                    services.AddLogging(configure => configure.AddConsole());
                });
    }
}
