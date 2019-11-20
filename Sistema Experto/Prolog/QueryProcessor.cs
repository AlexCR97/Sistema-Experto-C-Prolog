using SbsSW.SwiPlCs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;

namespace SistemaExperto.Prolog
{
    public static class QueryProcessor
    {
        public static bool ProcessForBoolean(string query)
        {
            var plQuery = new PlQuery(query);
            return plQuery.NextSolution();
        }

        public static List<string> ProcessForList(string query)
        {
            var list = new List<string>();
            var plQuery = new PlQuery(query);

            while (plQuery.NextSolution())
            {
                foreach (string id in plQuery.VariableNames)
                {
                    list.Add(plQuery.Variables[id].ToString());
                }
            }

            return list;
        }

        public static List<Dictionary<string, string>> ProcessForResults(string query)
        {
            var results = new List<Dictionary<string, string>>();
            var plQuery = new PlQuery(query);

            while (plQuery.NextSolution())
            {
                var variables = new Dictionary<string, string>();

                foreach (string id in plQuery.VariableNames)
                {
                    variables[id] = plQuery.Variables[id].ToString();
                }

                results.Add(variables);
            }

            return results;
        }

        public static string ProcessForString(string query)
        {
            List<string> list = ProcessForList(query);

            if (list.Count == 0)
                return "";

            return list[0];
        }
    }
}
