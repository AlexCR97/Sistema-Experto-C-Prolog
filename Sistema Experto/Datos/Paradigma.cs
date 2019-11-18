using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public sealed class Paradigma : StringEnum
    {
        public static readonly Paradigma Imperativo = new Paradigma("Imperativo");
        public static readonly Paradigma Declarativo = new Paradigma("Declarativo");
        public static readonly Paradigma Estructurado = new Paradigma("Estructurado");
        public static readonly Paradigma OrientadoObjetos = new Paradigma("Orientado a Objetos");
        public static readonly Paradigma Funcional = new Paradigma("Funcional");
        public static readonly Paradigma Logico = new Paradigma("Logico");

        private Paradigma(string id) : base(id) { }
    }
}
