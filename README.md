# Charon

Charon is a macOS file monitoring application that automatically moves files based on their applied tags, leveraging macOS metadata and filesystem event monitoring to detect and process changes in real time. Users can define custom rules that map specific tags to destination directories, ensuring seamless organization of files.

## Features

- **Real-time Monitoring:** Watches a user-specified directory for file changes.
- **Tag-Based Rules:** Define rules that move files based on their tags.
- **Flexible Rule Matching:** Supports `any`, `all`, and `exclusive` tag match types.
- **User-Friendly Configuration:** Configure rules via a simple UI.
- **Persistent Storage:** Rules are stored in JSON format for easy management.

## Usage

1. Upon launching, Charon adds an icon to the macOS menu bar.
2. Grant access to the directory you want to monitor.
3. Use the "Manage Rules" menu option to define tag-to-folder mappings.
4. Any tagged files in the monitored directory will be automatically moved according to the configured rules.

## Configuration

Rules are stored in:

```
~/Library/Application Support/Charon/rules.json
```

Each rule consists of:

```json
{
  "tags": ["Invoice", "ClientName"],
  "matchType": "any",
  "destination": "~/Documents/Invoices/Archived"
}
```

- **`tags`**: List of tags to match.
- **`matchType`**: Defines how tags are matched (`any`, `all`, or `exclusive`).
- **`destination`**: The directory where matching files should be moved.

## License

Copyright (c) 2025 Zach Bonner

All rights reserved.

This source code is provided for **educational purposes only**.

### Permissions:

- You may view and read this code to **learn** about the author's development practices and coding style.

### Restrictions:

- You **may not** modify, distribute, sublicense, or use this code in any form, including personal, commercial, or open-source projects.
- You **may not** incorporate any part of this code into another project.
- You **may not** use this code in any compiled, interpreted, or executed format.
- You **may not** claim authorship or derive work from this project.

### Liability:

This code is provided **as-is**, without warranty of any kind. The author is not responsible for any use or misuse of this code.

For inquiries, please contact Zach.

## Contributing

Since this code is for educational purposes only, contributions are **not accepted**. However, you are welcome to study and learn from the codebase.

## Acknowledgments

Created by Zachary Bonner.&#x20;

