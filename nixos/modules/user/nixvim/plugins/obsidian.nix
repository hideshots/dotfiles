{ pkgs, lib, ... }:
let
  obsWorkspaces = [
    {
      name = "Personal";
      path = "~/Vaults/Personal";
    }
  ];
in {
  programs.nixvim = {
    plugins.obsidian = {
      enable   = true;
      autoLoad = true;
      settings.workspaces = obsWorkspaces;
      settings = {
        note_id_func = ''
          function(title)
              if title then
                return title
                  :gsub(" ", "-")
                  :gsub("[^A-Za-z0-9-]", "")
                  :lower()
              else
                return tostring(os.time())
              end
            end
              '';
              note_path_func = ''
          function(spec)
            return (spec.dir / spec.id):with_suffix(".md")
          end
        '';
      };
    };

    keymaps = [
      # Open in Obsidian app
      { mode = "n"; key = "<leader>oo"; action = "<cmd>ObsidianOpen<CR>"; options = { desc = "Open in App"; noremap = true; silent = true; }; }

      # New note
      { mode = "n"; key = "<leader>on"; action = "<cmd>ObsidianNew<CR>"; options = { desc = "New Note"; noremap = true; silent = true; }; }

      # Quick switch
      { mode = "n"; key = "<leader>oq"; action = "<cmd>ObsidianQuickSwitch<CR>"; options = { desc = "Notes List"; noremap = true; silent = true; }; }

      # Follow link
      { mode = "n"; key = "<leader>of"; action = "<cmd>ObsidianFollowLink<CR>"; options = { desc = "Follow Link"; noremap = true; silent = true; }; }

      # Backlinks
      { mode = "n"; key = "<leader>ob"; action = "<cmd>ObsidianBacklinks<CR>"; options = { desc = "Back Links"; noremap = true; silent = true; }; }

      # Tags
      { mode = "n"; key = "<leader>ot"; action = "<cmd>ObsidianTags<CR>"; options = { desc = "Tags"; noremap = true; silent = true; }; }

      # Daily notes
      { mode = "n"; key = "<leader>od"; action = "<cmd>ObsidianToday<CR>"; options = { desc = "Daily"; noremap = true; silent = true; }; }
      { mode = "n"; key = "<leader>oy"; action = "<cmd>ObsidianYesterday<CR>"; options = { desc = "Yesterday"; noremap = true; silent = true; }; }
      { mode = "n"; key = "<leader>om"; action = "<cmd>ObsidianTomorrow<CR>"; options = { desc = "Tomorrow"; noremap = true; silent = true; }; }
      { mode = "n"; key = "<leader>oD"; action = "<cmd>ObsidianDailies<CR>"; options = { desc = "Dailies"; noremap = true; silent = true; }; }

      # Linking
      { mode = "v"; key = "<leader>ol"; action = "<cmd>ObsidianLink<CR>"; options = { desc = "Link"; noremap = true; silent = true; }; }
      { mode = "v"; key = "<leader>oL"; action = "<cmd>ObsidianLinkNew<CR>"; options = { desc = "New Link"; noremap = true; silent = true; }; }

      # Paste images & rename
      { mode = "n"; key = "<leader>oP"; action = "<cmd>ObsidianPasteImg<CR>"; options = { desc = "Paste Image"; noremap = true; silent = true; }; }
      { mode = "n"; key = "<leader>or"; action = "<cmd>ObsidianRename<CR>"; options = { desc = "Rename"; noremap = true; silent = true; }; }

      # Extract & workspaces
      { mode = "v"; key = "<leader>ox"; action = "<cmd>ObsidianExtractNote<CR>"; options = { desc = "Extract Note"; noremap = true; silent = true; }; }
      { mode = "n"; key = "<leader>ow"; action = "<cmd>ObsidianWorkspace<CR>"; options = { desc = "Switch Workspace"; noremap = true; silent = true; }; }

      # Table of Contents
      { mode = "n"; key = "<leader>oc"; action = "<cmd>ObsidianTOC<CR>"; options = { desc = "Table of Contents"; noremap = true; silent = true; }; }
    ];
  };

  home.activation.createObsWorkspaces = lib.mkAfter ''
  # Ensure every Obsidian workspace directory exists
    ${lib.concatStringsSep "\n"
    (map (ws: "mkdir -p ${ws.path}") obsWorkspaces)}
  '';
}
