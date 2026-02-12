import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileHeader extends StatelessWidget {
  final UserModel user;

  const UserProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(user.avatarUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.login,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                     if (user.twitterUsername != null)
                      Text(
                        '@${user.twitterUsername}',
                        style: TextStyle(
                            color: theme.colorScheme.primary, fontSize: 13),
                      ),
                    const SizedBox(height: 4),
                    if (user.bio.isNotEmpty)
                      Text(
                        user.bio,
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (user.company != null)
                          _buildIconText(Icons.business, user.company!, theme),
                        if (user.location != null)
                          _buildIconText(Icons.location_on, user.location!, theme),
                        if (user.blog != null && user.blog!.isNotEmpty)
                          GestureDetector(
                            onTap: () async {
                                final urlString = user.blog!.startsWith('http') ? user.blog! : 'https://${user.blog}';
                                final url = Uri.parse(urlString);
                                if (await canLaunchUrl(url)) {
                                  launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                            },
                             child: _buildIconText(Icons.link, user.blog!, theme, color: theme.colorScheme.primary),
                          ),
                         if (user.createdAt != null)
                          _buildIconText(Icons.calendar_today, 'Joined ${DateFormat.yMMMd().format(user.createdAt!)}', theme),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(context, 'Repos', user.publicRepos.toString()),
              _buildStat(context, 'Followers', user.followers.toString()),
              _buildStat(context, 'Following', user.following.toString()),
            ],
          ),
          const SizedBox(height: 24),
          // Heatmap from ghchart.rshah.org
          Text('Contributions', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
             height: 120, // Explicit height container
             width: double.infinity,
             decoration: BoxDecoration(
               color: theme.colorScheme.surfaceContainer,
               borderRadius: BorderRadius.circular(12),
             ),
             padding: const EdgeInsets.all(8),
             child: SingleChildScrollView( // Make horizontal scroll if it's wide
                scrollDirection: Axis.horizontal,
                child: SvgPicture.network(
                  'https://ghchart.rshah.org/43A047/${user.login}',
                  placeholderBuilder: (BuildContext context) => const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )),
                  // Provide width to ensure it renders if intrinsic failing
                  // Usually ghchart is wide.
                  fit: BoxFit.fitHeight,
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, ThemeData theme, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? theme.colorScheme.outline),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: TextStyle(fontSize: 12, color: color ?? theme.colorScheme.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
        ),
      ],
    );
  }
}

