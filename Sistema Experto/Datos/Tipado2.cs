using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public sealed class Tipado2 : StringEnum
    {
        public static readonly Tipado2 Dinamico = new Tipado2("Dinámico");
        public static readonly Tipado2 Estatico = new Tipado2("Estático");
        public static readonly Tipado2 Pato = new Tipado2("Pato");

        private Tipado2(string id) : base(id) { }
    }
}
