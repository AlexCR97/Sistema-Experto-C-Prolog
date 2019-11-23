using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public class Frameworks
    {
        public string Id { get; set; }
        public string Nombre { get; set; }
        public string Descripcion { get; set; }
        public List<string> Ventajas { get; set; }
        public List<string> Desventajas { get; set; }
        public string Plataforma { get; set; }
        public string SistemaOperativo { get; set; }
        public List<string> Lenguajes { get; set; }
        public string Tipado1 { get; set; }
        public List<string> Tipaado2 { get; set; }
        public List<string> Paradigmas { get; set; }
        public string LadoDesarrollo { get; set; }
        public List<string> Ides { get; set; }

        public override string ToString()
        {
            return "Framework{\n" +
                $"  Id: {Id}\n" +
                $"  Nombre: {Nombre}\n" +
                $"  Descripcion: {Descripcion}\n" +
                $"  Ventajas: {String.Join(", ", Ventajas)}\n" +
                $"  Desventajas: {String.Join(", ", Desventajas)}\n" +
                $"  Plataforma: {Plataforma}\n" +
                $"  Sistema Operativo: {SistemaOperativo}\n" +
                $"  Lenguaje: {String.Join(", ", Lenguajes)}\n" +
                $"  Tipado1: {Tipado1}\n" +
                $"  Tipado2: {String.Join(", ", Tipaado2)}\n" +
                $"  Paradigmas: {String.Join(", ", Paradigmas)}\n" +
                $"  Lado de desarrollo: {LadoDesarrollo}\n" +
                $"  IDEs: {String.Join(", ", Ides)}\n" +
                "}";
        }
    }
}
